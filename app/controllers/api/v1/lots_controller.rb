module Api
  module V1
    class LotsController < BaseController
      def index
        lots = Item.find(params[:item_id]).lots.fefo
        render json: { lots: lots.map { |lot| LotSerializer.new(lot) } }
      end
    end
  end
end
