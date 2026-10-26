module Api
  module V1
    class IssuesController < BaseController
      def create
        movements = Stock::Issue.call(
          item: Item.find(params.require(:item_id)),
          warehouse: Warehouse.find(params.require(:warehouse_id)),
          quantity: params.require(:quantity),
          reason: params[:reason],
          user: current_user
        )
        render_movements movements
      end
    end
  end
end
