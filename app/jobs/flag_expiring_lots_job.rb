class FlagExpiringLotsJob < ApplicationJob
  WINDOW_IN_DAYS = 30

  limits_concurrency to: 1, key: "flag_expiring_lots"

  def perform(on: Date.current)
    lots = ExpiringLotsReport.new(within_days: WINDOW_IN_DAYS, on: on).rows.map(&:lot).uniq
    lots = lots.select { |lot| lot.expiry_alerted_at.nil? }
    return if lots.empty?

    Lot.where(id: lots).update_all(expiry_alerted_at: Time.current)
    User.find_each { |user| ExpiryMailer.with(user: user, lots: lots).expiring_soon.deliver_later }
  end
end
