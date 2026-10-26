module Api
  module V1
    class IssuesController < BaseController
      def create
        create_movements do
          Stock::Issue.call(
            item: Item.find(params.require(:item_id)),
            warehouse: Warehouse.find(params.require(:warehouse_id)),
            quantity: params.require(:quantity),
            reason: params[:reason],
            user: current_user
          )
        end
      end
    end
  end
end
