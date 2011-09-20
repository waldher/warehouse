class CustomersController < ApplicationController

  respond_to :html, :xml, :json

  before_filter :authenticate_admin!, :except => [:first_login, :login, :logout]

  def index
  end

  def show
  end

  def new
    respond_with(@customer = Customer.new)
  end

  def first_login
    @customer = Customer.where(:setup_nonce => params[:setup_nonce]).first

    redirect_to(login_url, :notice => "That URL is invalid.") and return if @customer.nil?

    if request.put?
      if @customer.update_attributes(params[:customer])
        redirect_to login_url, :notice => "password successfully changed"
      else 
        render :first_login
      end
    end
  end

  def login
    if request.post?
      @customer = Customer.authenticate(params['email'], params['password'])
      if @customer.present?
        url = ""
        if(@customer.role_id == 1 && @customer.customer_infos.empty?) 
          url = new_customer_infos_url 
        elsif(@customer.role_id == 1 && @customer.customer_infos.present?)
          url = edit_customer_infos_url
        elsif(@customer.id == 2) 
          url = root_url # this need to change
        end
        session[:user_id] = @customer.id
        redirect_to url, :notice => "You have successfully logged in."
      else
        flash.now[:notice] = "email/password combination wrong. please try again"
        render :login
      end
    end
  end

  def logout
    if @current_user.present?
      @current_user = nil
      session[:user_id] = nil
      flash.notice = "You have successfully logged out"
    end
      redirect_to login_url
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

    if @customer.update_attributes!(params[:customer])
      flash.notice = "Customer updated successfully"
    end

    redirect_to(@customer)
  end

end
