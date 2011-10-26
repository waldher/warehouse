class LocationsController < ApplicationController

  before_filter :find_location, :except => [:index, :new, :create]
  respond_to :html, :xml, :json

  def index
    respond_with(@locations = Location.order("name ASC"))
  end

  def show
    @sublocations = @location.sublocations
    respond_with(@location)
  end

  def new
    @location = Location.new
  end
  
  def create
    @location = Location.new(params[:location])
    flash.notice = "Location Added successfully." if @location.save
    respond_with(@location)
  end

  def edit
  end


  def update
    flash.notice = "Location updated successfully" if @location.update_attributes(params[:location])
    respond_with(@location)
  end


  def destroy
    @location.destroy 
    flash.notice = "Location destroyed successfully."  if @location.destroyed?
    respond_with(@location)
  end

  private 

  def find_location
    @location = Location.where(:id => params[:id]).first
  end

end
