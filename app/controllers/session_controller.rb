class SessionController < ApplicationController
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
        if(@customer.customer_infos.empty?) 
          url = new_customer_infos_url 
        elsif(@customer.customer_infos.present?)
          url = edit_customer_infos_url
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
end
