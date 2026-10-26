# Stockroom

[![CI](https://github.com/diogoalvespinto/stockroom/actions/workflows/ci.yml/badge.svg)](https://github.com/diogoalvespinto/stockroom/actions/workflows/ci.yml)

Lot-based inventory management for a small organisation with several storage locations,
built with Rails 8.1 and PostgreSQL 18 as a showcase of automated testing.

Stock is received in lots with an expiry date, issued first-expiry-first-out, moved between
warehouses and adjusted with a reason. Every change is a row in an append-only ledger, and
the current stock is always derived from it.

## Contents

- [Domain rules](#domain-rules)
- [Architecture decisions](#architecture-decisions)
- [Running it](#running-it)
- [API](#api)
- [Testing strategy](#testing-strategy)
- [What I'd do next](#what-id-do-next)

## Domain rules

- **Stock never goes negative**, per lot and per warehouse.
- **Issues are allocated FEFO** (first expiry, first out). One request can be split across
  several lots. Lots without an expiry date are used last.
- **Expired lots are never issued.** A lot is still usable on its expiry date. Expired lots
  can still be transferred, for example into quarantine.
- **A transfer is atomic**: the `transfer_out` and `transfer_in` movements are written in one
  database transaction and share a `transfer_id`.
- **Adjustments require a reason.**
- **Two simultaneous issues cannot overdraw a lot.** This is covered by a spec that runs two
  threads at once.
- **Creating movements through the API is idempotent** via the `Idempotency-Key` header.
- **Reports**: stock on hand per warehouse and lot, lots expiring within N days, and items whose
  usable stock is below their reorder level.
- **A daily job** (Active Job on Solid Queue, no Redis) flags lots expiring within 30 days and
  emails a digest.

## Architecture decisions

### A ledger instead of a balance

`stock_movements` is the only source of truth. Quantities are signed (receipts and incoming
transfers are positive, issues and outgoing transfers negative), so a balance is
`SUM(quantity)` for a lot in a warehouse. There is no mutable balance column to drift, every
movement records who made it (and why, for adjustments), and the stock at any past date can be
reconstructed.

The ledger is protected at two levels:

- `StockMovement#readonly?` is true once a movement is persisted.
- A PL/pgSQL trigger rejects every `UPDATE` and `DELETE`, so `update_all`, `delete_all` or raw
  SQL cannot rewrite history either. Mistakes are corrected with a compensating adjustment.
  The trigger is why the schema is dumped as `db/structure.sql`.

Every rule lives in the model *and* in the database: `NOT NULL`, unique indexes, foreign keys
and check constraints, including one that ties the sign of the quantity to the movement kind.
Validations give good error messages; constraints hold even when the model is bypassed. The
model specs test both, saving with `validate: false` to prove the constraint fires.

**The cost is that balances are sums.** I measured it with one million movements over 20,000
lots, on a laptop with the data cached in memory:

| Query | Result |
| --- | --- |
| FEFO balances of an item's 200 lots | 10,600 → 650 buffer reads after adding `INCLUDE (quantity)` to the `(warehouse_id, lot_id)` index (an index-only scan) |
| Stock on hand, one warehouse | 94 ms |
| Lots expiring within 30 days | 30 ms |
| Items below reorder level | 38 ms |
| Stock on hand, every lot in every warehouse | 522 ms, mostly building 20,000 rows |

Before measuring I weighed snapshots, a materialized view and a trigger-maintained balance
table. I rejected snapshots because a movement id is assigned at insert time, not at commit
time, so a slow transaction can be missed by a snapshot's cut-off. A materialized view is
stale between refreshes, so it can never decide whether an issue may proceed. A projection
table maintained by a trigger would be fast, but it is a stored balance. The numbers above
did not justify any of them.

### FEFO and row locking

`Stock::Issue` locks the item's usable lots with `SELECT … FOR UPDATE`, always in FEFO order
so two issues can never deadlock. Only then does it read the balances and let
`Stock::Allocation` split the request. `Stock::Allocation` is a plain Ruby object whose spec
runs in milliseconds without Rails or a database.

The concurrency spec forces the worst interleaving. A barrier holds each thread right after
it reads the balances: without the lock, both threads issue 7 from a lot holding 10 and the
lot ends at −4. With the lock, the second thread waits, sees 3 and is refused.

Locking per lot means two issues of the same item in different warehouses also wait for each
other. That keeps the design simple; see [What I'd do next](#what-id-do-next).

### Idempotent API

`POST` endpoints that create movements require an `Idempotency-Key` header. `IdempotentRequest`
claims the key with `INSERT … ON CONFLICT DO NOTHING` in the *same transaction* as the
movements. As a result:

- a retry gets the stored response replayed byte for byte, with `Idempotent-Replayed: true`;
- a concurrent duplicate waits on the unique index, then replays;
- a failed request rolls back its key, so the client can retry once the cause is fixed;
- reusing a key with a different body is refused;
- keys are scoped per user and purged after 24 hours.

### Other choices

- **Service objects** (`Stock::Receive`, `Issue`, `Transfer`, `Adjust`) hold the business rules,
  and controllers, form objects, seeds and specs all call them.
- **Plain serializer classes** build the API JSON instead of Jbuilder views, so each payload is
  tested directly.
- **Form objects** (`ReceiptForm`, `IssueForm`) turn domain errors into form errors, so
  controllers stay a plain save-or-render.
- **Report objects** (`StockOnHandReport`, `ExpiringLotsReport`, `BelowReorderLevelReport`) feed
  both the UI and the API.
- **Hotwire**: filters are plain GET forms targeting a Turbo Frame, with a ten-line Stimulus
  controller that submits on change. They still work without JavaScript.
- **API tokens** are random 32-character strings stored as SHA-256 digests. The plain token is
  shown once.

## Running it

Requirements: Ruby 4.0.9 (see `.ruby-version`), Docker, and Google Chrome for the browser specs.

```bash
docker compose up -d   # PostgreSQL 18 on localhost:5433
bin/setup              # installs gems, creates and seeds the databases, starts the server
```

Open http://localhost:3000 and sign in as `demo@example.com` with the password `password`.
The seeds go through the stock services, so the demo data obeys the same rules: one issue
split across two lots, a transfer, an adjustment, an expired lot, lots about to expire and
items below their reorder level.

## API

Create a token for a user. It is printed once:

```bash
bin/rails api_tokens:create EMAIL=demo@example.com NAME=laptop
```

```bash
TOKEN=...
curl -H "Authorization: Bearer $TOKEN" localhost:3000/api/v1/stock

curl -X POST localhost:3000/api/v1/issues \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{"item_id": 1, "warehouse_id": 1, "quantity": 5, "reason": "ward 3"}'
```

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/api/v1/warehouses` | |
| GET | `/api/v1/items` | |
| GET | `/api/v1/items/:item_id/lots` | in FEFO order |
| GET | `/api/v1/stock` | `?warehouse_id=` optional |
| GET | `/api/v1/reports/expiring_lots` | `?days=` from 1 to 365, default 30 |
| GET | `/api/v1/reports/below_reorder_level` | |
| POST | `/api/v1/receipts` | `item_id, warehouse_id, lot_number, expiry_date, quantity` |
| POST | `/api/v1/issues` | `item_id, warehouse_id, quantity, reason` |
| POST | `/api/v1/transfers` | `lot_id, from_warehouse_id, to_warehouse_id, quantity` |
| POST | `/api/v1/adjustments` | `lot_id, warehouse_id, quantity, reason` (quantity is signed) |

Every `POST` requires `Idempotency-Key` and answers `201` with `{ "movements": [...] }`.
Every error has the same shape:

```json
{ "error": { "code": "insufficient_stock", "message": "Requested 20 but only 13 available",
             "details": { "requested": 20, "available": 13 } } }
```

| Status | When |
| --- | --- |
| `400` | malformed JSON, a missing field or an invalid `Idempotency-Key` |
| `401` | a missing or unknown token |
| `404` | an unknown record or path |
| `422` | a business-rule or validation failure, or a reused idempotency key |

## Testing strategy

```bash
bin/rspec        # the suite; coverage report in coverage/index.html
CI=1 bin/rspec   # as CI runs it: eager loading and coverage thresholds
bin/ci           # RuboCop, bundler-audit, importmap audit, Brakeman and RSpec

SHOW_BROWSER=1 bin/rspec spec/system   # watch the browser specs in a visible Chrome
```

| Layer | Examples | What it proves |
| --- | --- | --- |
| Models | 72 | validations and associations (shoulda-matchers), plus the database constraints and the append-only trigger with validations bypassed |
| Services | 50 | every business rule: FEFO, expiry, atomic transfers and idempotency, with two thread-based concurrency specs |
| Requests | 49 | the API contract, authentication, the error format and idempotent replays, plus the sign-in and password reset flows |
| System | 15 | UI flows with `rack_test`; Turbo Frames and Stimulus in headless Chrome |
| Reports, forms, jobs, mailers and others | 40 | query objects, form objects, the daily job, emails, `recurring.yml`, seeds and the rake task |

Principles I followed:

- **Red before green.** Each important spec was seen failing for the right reason first: the
  concurrency spec without the lock, the idempotency spec without the key, the atomic transfer
  without its transaction.
- **Specs that can fail.** When a spec passed on the first run, I broke the code on purpose
  to confirm the spec catches it.
- **Committed data only where needed.** Concurrency specs run outside the test transaction,
  because each thread has its own connection, and clean up with `TRUNCATE`. `DELETE` is
  blocked by the trigger.
- **Browser specs only for JavaScript.** `rack_test` is the default driver; Chrome runs only for
  examples tagged `js: true`. Those specs mark an element outside the Turbo Frame to prove the
  page was not replaced.
- **Flaky specs are diagnosed, not retried.** Chrome's password manager was wiping fields
  typed into the sign-in form. The fix (incognito mode) is explained in the commit that made it.

**Coverage**: 100% of lines and 97% of branches at the time of writing. CI fails below 95% of
lines or 90% of branches. Line coverage only says a line ran, which is why branches are
measured and the threshold is a floor rather than a target.

**CI** (GitHub Actions) runs RuboCop, Brakeman, bundler-audit, importmap audit and the full
suite against a PostgreSQL 18 service. The coverage report is kept as a build artifact.

## What I'd do next

- **Paginate the stock list.** Listing all 20,000 lots takes half a second, almost all of it
  building rows that no one could read on one page.
- **Finer locks.** `pg_advisory_xact_lock` on (warehouse, lot) would let issues of the same item
  in different warehouses run in parallel, if contention ever showed up.
- **Manage API tokens in the UI**, with revocation and last-used dates (already recorded).
- **An OpenAPI description** generated from the request specs.
- **Roles**: today every signed-in user can do everything.
