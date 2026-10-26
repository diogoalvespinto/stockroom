module Api
  module V1
    class StockController < BaseController
      def index
        warehouse = Warehouse.find(params[:warehouse_id]) if params[:warehouse_id].present?
        rows = StockOnHandReport.new(warehouse: warehouse).rows

        render json: { stock: rows.map { |row| StockRowSerializer.new(row) } }
      end
    end
  end
end
