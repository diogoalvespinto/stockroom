module Api
  module V1
    class StockController < BaseController
      class InvalidCursor < StandardError; end

      rescue_from InvalidCursor do
        render_error :bad_request, "invalid_parameter", "after must be a next_cursor returned by this endpoint"
      end

      def index
        warehouse = Warehouse.find(params[:warehouse_id]) if params[:warehouse_id].present?
        page = StockOnHandReport.new(warehouse: warehouse).after(decode_cursor(params[:after]))

        render json: {
          stock: page.rows.map { |row| StockRowSerializer.new(row) },
          next_cursor: encode_cursor(page.next_after)
        }
      end

      private
        def encode_cursor(position)
          Base64.urlsafe_encode64(position.join(":"), padding: false) if position
        end

        def decode_cursor(cursor)
          return if cursor.blank?

          position = Base64.urlsafe_decode64(cursor.to_s).match(/\A(\d+):(\d+)\z/)&.captures
          raise InvalidCursor unless position

          position.map(&:to_i)
        rescue ArgumentError
          raise InvalidCursor
        end
    end
  end
end
