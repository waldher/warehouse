class DealersController < ApplicationController


  def index
    @dealers = Customer.dealers
  end


  def show
    @dealer = Dealer.find(params[:id])
    url = URI.parse("http://palermo.blinkonlinemarketing.com/posts/dealers/#{dealer.dealer_key}")
    #url = URI.parse("http://palermo.blinkonlinemarketing.com/locations/1/hosts/")
    req = Net::HTTP::Get.new(url.path)
    req.basic_auth 'support@blinkonlinemarketing.com', 'popsicles'
    res = Net::HTTP.new(url.host, url.port).start{|http| http.request(req)}
    @posts = ActiveSupport::JSON.decode(res.body)
  end

  def dealer_infos
    dealer = Dealer.find(params[:dealer_id])
    @dealer_infos = DealerInfo.where(:dealer_id => dealer.id)
    render :json => @dealer_infos.to_json
  end

end
