class IdempotentRequest
  Response = Data.define(:status, :body, :replayed)

  class KeyReused < StandardError
    def initialize
      super("This Idempotency-Key was already used with a different request")
    end
  end

  def initialize(user:, key:, fingerprint:)
    @user = user
    @key = key
    @fingerprint = fingerprint
  end

  def call
    IdempotencyKey.transaction do
      claimed = IdempotencyKey.insert(
        { user_id: @user.id, key: @key, request_digest: @fingerprint },
        unique_by: %i[user_id key], returning: :id
      ).first
      return replay unless claimed

      status, body = yield
      IdempotencyKey.where(id: claimed["id"]).update_all(response_status: status, response_body: body)
      Response.new(status: status, body: body, replayed: false)
    end
  end

  private
    def replay
      stored = IdempotencyKey.find_by!(user: @user, key: @key)
      raise KeyReused unless stored.request_digest == @fingerprint

      Response.new(status: stored.response_status, body: stored.response_body, replayed: true)
    end
end
