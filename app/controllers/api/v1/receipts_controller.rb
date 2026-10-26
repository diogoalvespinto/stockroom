module Api
  module V1
    class ReceiptsController < BaseController
      def create
        create_movements do
          movement = Stock::Receive.call(
            item: Item.find(params.require(:item_id)),
            warehouse: Warehouse.find(params.require(:warehouse_id)),
            lot_number: params.require(:lot_number),
            expiry_date: params[:expiry_date],
            quantity: params.require(:quantity),
            user: current_user
          )
          [ movement ]
        end
      end
    end
  end
end
