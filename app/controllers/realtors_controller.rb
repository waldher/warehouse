class RealtorsController < ApplicationController

  before_filter :authenticate_admin!, :only => :index

  def index
    @realtors = Customer.realtors
  end

  def show
  end

  def new
  end

  def edit
  end

end
