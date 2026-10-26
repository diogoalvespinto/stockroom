module Api
  module V1
    class TransfersController < BaseController
      def create
        movements = Stock::Transfer.call(
          lot: Lot.find(params.require(:lot_id)),
          from: Warehouse.find(params.require(:from_warehouse_id)),
          to: Warehouse.find(params.require(:to_warehouse_id)),
          quantity: params.require(:quantity),
          user: current_user
        )
        render_movements movements
      end
    end
  end
end
