class ApiToken < ApplicationRecord
  belongs_to :user

  attr_reader :token

  validates :name, presence: true

  before_create :generate_token

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token)
  end

  def self.authenticate(token)
    return if token.blank?

    find_by(token_digest: digest(token))&.tap { |api_token| api_token.touch(:last_used_at) }
  end

  private
    def generate_token
      @token = SecureRandom.base58(32)
      self.token_digest = self.class.digest(@token)
    end
end
