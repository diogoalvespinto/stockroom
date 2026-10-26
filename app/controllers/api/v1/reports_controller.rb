module Api
  module V1
    class ReportsController < BaseController
      def expiring_lots
        days = Integer(params.fetch(:days, ExpiringLotsReport::DEFAULT_WINDOW).to_s, exception: false)
        unless days&.between?(1, 365)
          return render_error :bad_request, "invalid_parameter", "days must be a whole number between 1 and 365"
        end

        report = ExpiringLotsReport.new(within_days: days)
        render json: {
          within_days: days,
          lots: report.rows.map { |row| StockRowSerializer.new(row, days_left: report.days_left(row.lot)) }
        }
      end

      def below_reorder_level
        rows = BelowReorderLevelReport.new.rows

        render json: {
          items: rows.map do |row|
            { item: ItemSerializer.new(row.item).as_json, usable_quantity: row.usable_quantity, shortfall: row.shortfall }
          end
        }
      end
    end
  end
end
