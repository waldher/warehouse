class DealersController < ApplicationController

  def show    
    @posts = ActiveSupport::JSON.decode(Net::HTTP.get_response(URI.parse("http://palermo.blinkonlinemarketing.com/posts/dealers/#{self.dealer_key}")).body)
  end

end
