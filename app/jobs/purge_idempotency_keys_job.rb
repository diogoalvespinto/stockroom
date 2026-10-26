class PurgeIdempotencyKeysJob < ApplicationJob
  RETENTION = 24.hours

  def perform
    IdempotencyKey.where(created_at: ...RETENTION.ago).delete_all
  end
end
