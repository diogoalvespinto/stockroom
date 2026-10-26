class ReportsController < ApplicationController
  def expiring
    days = params[:days].to_i
    days = ExpiringLotsReport::DEFAULT_WINDOW unless ExpiringLotsReport::WINDOWS.include?(days)
    @report = ExpiringLotsReport.new(within_days: days)
  end

  def below_reorder_level
    @rows = BelowReorderLevelReport.new.rows
  end
end
