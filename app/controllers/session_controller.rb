class SessionController < ApplicationController

  def first_login
    @customer = Customer.where(:setup_nonce => params[:setup_nonce]).first

    redirect_to(login_url, :notice => "We are sorry, this link no longer works. Please contact us at support@leadadvo.com or 888-23106434 for further assistance.") and return if @customer.nil?

    if request.put?
      if @customer.update_attributes(params[:customer])
        session[:user_id] = @customer.id
        redirect_to login_url, :notice => "Password successfully updated."
      else 
        render :first_login
      end
    end
  end

  def login
    if request.post?
      @customer = Customer.authenticate(params['email'], params['password'])
      if @customer.present?
        
        session[:user_id] = @customer.id
        redirect_to customer_listings_path(@customer), :notice => "Logged in successfully"
      else
        flash.now[:notice] = "Email or password is incorrect, please try again."
        render :login
      end
    end
  end

  def logout
    if current_user
      @current_user = nil
      session[:user_id] = nil
      flash.notice = "Logged out successfully"
    end
      redirect_to login_url
  end
end
