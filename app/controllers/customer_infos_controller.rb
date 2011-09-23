class CustomerInfosController < ApplicationController

  before_filter :authenticated?

  def show
    @latest_infos = @current_user.latest_infos
  end

  def new
    @infos = {}
    redirect_to customer_infos_url and return if @current_user.latest_infos.present?
    # TODO: for handling different type of users if can be use 
    fields = []
    if @current_user.craigslist_type == 'apa' # Realtor 
      fields = %w(Name Phone_Number Address Properties)
    elsif @current_user.craigslist_type = 'ctd' # Dealer
      fields = %w(Name Phone_Number Address Car_Models)
    end

    fields.each { |attr| 
      @current_user.latest_infos.build(:key => attr.humanize) 
    }
  end

  def create
    #redirect_to customer_infos_url and return if @current_user.latest_infos.present?
    begin 
      @current_user.latest_infos_attributes=(params[:customer][:latest_infos_attributes])
      @current_user.save!
      redirect_to customer_infos_url, :notice => "You are coming back from create action"
    rescue Exception => e
      @infos = {}
      redirect_to edit_customer_infos_url, :notice => "There was an error while saving the record please try again"
    end
  end

  def edit
    info = {}
    @infos = @current_user.latest_infos.map {|i| info[i.key.downcase.to_sym] = i.value }
    @infos = info
  end

  def update
    @current_user.maintain_history(params[:customer][:latest_infos_attributes])
    redirect_to customer_infos_url, :notice => "Information updated successfully" 
  end

end
