class ApplicationController < ActionController::Base
  protect_from_forgery


  helper_method :current_user, :logged_in?

  def authenticated?
    unless current_user
      redirect_to login_url, :notice => "Please sign in."
      return
    end
  end

  def current_user
    @current_user = Customer.where(:id =>session[:user_id]).first
  end

  def logged_in?
    !!current_user
  end

  def after_sign_in_path_for(resource) 
    if resource.is_a?(Admin)
      admin_index_url
    else
      super
    end
  end

  def after_sign_out_path_for(resource_or_scope) 
    logger.debug resource_or_scope
    if resource_or_scope == :admin
       new_admin_session_url
    else
      super
    end
  end

end
