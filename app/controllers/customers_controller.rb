class CustomersController < ApplicationController

  respond_to :html, :xml, :json

  before_filter :authenticate_admin!

  def index
  end

  def show
  end

  def new
    respond_with(@customer = Customer.new)
  end

  def create
    @customer = Customer.new(params[:customer])
    if @customer.save
      flash.notice = "Customer created successfully"
    end
    redirect_to(@customer)
  end

  def edit
    @customer = Customer.find(params[:id])
  end

  def update
    @customer = Customer.find(params[:id])
    flash.notice = "Customer updated successfully" if @customer.update_attributes!(params[:customer])
    redirect_to(@customer)
  end

end
