class CustomerInfosController < ApplicationController

  before_filter :authenticated?

  def show
    @latest_infos = @current_user.latest_infos
  end

  def new
    @current_user.latest_infos.build
  end

  def create
    begin 
      @current_user.latest_infos_attributes=(params[:customer][:latest_infos_attributes])
      @current_user.save!
      redirect_to new_customer_info_url, :notice => "You are coming back from create action"
    rescue Exception => e
      redirect_to new_customer_info_url, :notice => "There was an error while saving the record please try again"
    end
  end

  def edit
  end

  def update
    @current_user.maintain_history(params[:customer][:latest_infos_attributes])
    redirect_to customer_infos_url, :notice => "Information updated successfully" 
  end

end
