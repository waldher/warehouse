class CustomersController < ApplicationController

  respond_to :html, :xml, :json

  before_filter :authenticate_admin!, :except => [:first_login, :login, :logout]

  def index
  end

  def show
  end

  def new
    @roles = Role.select([:id, :name])
    respond_with(@customer = Customer.new)
  end

  def first_login
    @customer = Customer.where(:key => params[:key]).first
    redirect_to(login_url, :notice => "Sorry key is expired") and return if @customer.nil?
    if request.put?
      if @customer.update_attributes(params[:customer])
        @customer.update_attribute(:key, nil)
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
        if(@customer.role_id == 1 && @customer.dealer_infos.empty?) 
          url = new_dealer_info_url 
        elsif(@customer.role_id == 1 && @customer.dealer_infos.present?)
          url = edit_dealer_info_url(@customer.id)
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
    @role = Role.find(params[:role_id])
    url = admin_index_url
    @customer = @role.customers.build(params[:customer])
    if @customer.save
      title = (@role.id == 1) ? "Dealer" : "Realtor"
      url = send("#{title.downcase.pluralize}_url")
      flash.notice = "#{title} created successfully"
    else
      @roles = Role.select([:id, :name])
    end
    respond_with(@customer, :location => url)
  end

  def edit
    @customer = Customer.find(params[:id])
    @roles = Role.select([:id, :name])
  end

  def update
    @customer = Customer.find(params[:id])
    url = admin_index_url
    if @customer.update_attributes(params[:customer])
      title = (@customer.role_id == 1) ? "Dealer" : "Realtor"
      url = send("#{title.downcase.pluralize}_url")
      flash.notice = "#{title} updated successfully"
    else
      @roles = Role.select([:id, :name])
    end
    respond_with(@customer, :location => url)
  end

end