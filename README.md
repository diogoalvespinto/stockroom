# Stockroom

Lot-based inventory management for a small organisation with several storage
locations. Work in progress.

## Requirements

- Ruby 4.0.9 (see `.ruby-version`)
- Docker (for PostgreSQL 18)
- Google Chrome (for JavaScript system specs)

## Getting started

```bash
docker compose up -d   # PostgreSQL on localhost:5433
bin/setup              # installs gems, prepares the databases, starts the server
```

## Running the checks

```bash
bin/rspec              # test suite; coverage report in coverage/index.html
CI=1 bin/rspec         # same, enforcing the coverage thresholds
bin/ci                 # everything CI runs: RuboCop, audits, Brakeman, RSpec
```

`SHOW_BROWSER=1 bin/rspec spec/system` runs browser specs in a visible Chrome window.
