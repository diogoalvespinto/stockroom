class IssuesController < ApplicationController
  before_action :set_choices

  def new
    @issue = IssueForm.new
  end

  def create
    @issue = IssueForm.new(issue_params)

    if @issue.save(user: Current.user)
      redirect_to root_path, notice: @issue.summary, status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def issue_params
      params.expect(issue: %i[item_id warehouse_id quantity reason])
    end

    def set_choices
      @items = Item.order(:sku)
      @warehouses = Warehouse.order(:code)
    end
end
