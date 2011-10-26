class SublocationsController < ApplicationController

  respond_to :xml, :html, :json

  before_filter :find_location

  def new
    @sublocation = @location.sublocations.build
    respond_with([@location, @sublocation])
  end


  def create
    @sublocation = @location.sublocations.build(params[:sublocation])
    flash.notice = "Sublocation added successfully." if @sublocation.save
    respond_with([@location, @sublocation], :location => @location)
  end

  def edit
    @sublocation = @location.sublocations.find(params[:id])
    respond_with([@location, @sublocation])
  end

  def update
    @sublocation = @location.sublocation.find(params[:id])
    flash.notice = "Sublocation updated succesffully." if @sublocation.update_attributes(params[:sublocation])
    respond_with([@location, @sublocation], :location => @location)
  end

  def destroy
    @sublocation = @location.sublocations.find(params[:id])
    @sublocation.destroy
    flash.notice = "Sublocation deleted successfully." if @sublocation.destroyed?
    respond_with([@location, @sublocation], :location => @location)
  end

  private

  def find_location
    @location = Location.find(params[:location_id])
  end


end
