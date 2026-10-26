class StockController < ApplicationController
  def index
    @warehouses = Warehouse.order(:code)
    @warehouse = @warehouses.find_by(id: params[:warehouse_id])
    @rows = StockOnHandReport.new(warehouse: @warehouse).rows
  end
end
