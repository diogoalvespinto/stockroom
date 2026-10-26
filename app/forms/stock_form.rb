class StockForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  private
    def perform
      return false if invalid?

      yield
      true
    rescue Stock::Error => error
      errors.add(:base, error.message)
      false
    end
end
