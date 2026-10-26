module Api
  module V1
    class AdjustmentsController < BaseController
      def create
        create_movements do
          movement = Stock::Adjust.call(
            lot: Lot.find(params.require(:lot_id)),
            warehouse: Warehouse.find(params.require(:warehouse_id)),
            quantity: params.require(:quantity),
            reason: params[:reason],
            user: current_user
          )
          [ movement ]
        end
      end
    end
  end
end
