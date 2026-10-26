module Api
  module V1
    class WarehousesController < BaseController
      def index
        render json: { warehouses: Warehouse.order(:code).map { |warehouse| WarehouseSerializer.new(warehouse) } }
      end
    end
  end
end
