class AdminController < ApplicationController

  before_filter :authenticate_admin!

  def index
    @customers = Customer.all
  end

end
