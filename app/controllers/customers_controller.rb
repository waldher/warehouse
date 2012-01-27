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
    redirect_to(admin_index_path)
  end

  def edit
    @customer = Customer.find(params[:id])
  end

  def update
    @customer = Customer.find(params[:id])
    flash.notice = "Customer updated successfully" if @customer.update_attributes!(params[:customer])
    redirect_to(admin_index_path)
  end
  
  def destroy
    @customer = Customer.find(params[:id])
    @customer.delete
    flash.notice = "Customer with email address #{@customer.email_address} deleted successfully."
    redirect_to(admin_index_path)
  end

  def reset_password
    @customer = Customer.find(params[:customer_id])
    @customer.set_setup_nonce.save!
    redirect_to admin_index_url
  end

end
