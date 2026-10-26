class ReceiptsController < ApplicationController
  before_action :set_choices

  def new
    @receipt = ReceiptForm.new
  end

  def create
    @receipt = ReceiptForm.new(receipt_params)

    if @receipt.save(user: Current.user)
      redirect_to root_path, notice: @receipt.summary, status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def receipt_params
      params.expect(receipt: %i[item_id warehouse_id lot_number expiry_date quantity])
    end

    def set_choices
      @items = Item.order(:sku)
      @warehouses = Warehouse.order(:code)
    end
end
