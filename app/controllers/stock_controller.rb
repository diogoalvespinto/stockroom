class StockController < ApplicationController
  def index
    @warehouses = Warehouse.order(:code)
    @warehouse = @warehouses.find_by(id: params[:warehouse_id])
    @page = StockOnHandReport.new(warehouse: @warehouse).page(params[:page].to_s.to_i.clamp(1..))
  end
end
