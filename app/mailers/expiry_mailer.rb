class ExpiryMailer < ApplicationMailer
  def expiring_soon
    @lots = params[:lots].sort_by(&:expiry_date)
    count = @lots.size

    mail to: params[:user].email_address,
      subject: "#{count} #{"lot".pluralize(count)} #{count == 1 ? "expires" : "expire"} within #{FlagExpiringLotsJob::WINDOW_IN_DAYS} days"
  end
end
