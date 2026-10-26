module Api
  module V1
    class ItemsController < BaseController
      def index
        render json: { items: Item.order(:sku).map { |item| ItemSerializer.new(item) } }
      end
    end
  end
end
