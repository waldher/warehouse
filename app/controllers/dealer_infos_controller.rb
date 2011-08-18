class DealerInfosController < ApplicationController
  # GET /dealer_infos/new
  # GET /dealer_infos/new.xml
  def new 
#    @last_dealer_info = DealerInfo.where(:dealer_id => current_dealer.id).order(:created_at).last

#    if @last_dealer_info.nil?
      @dealer_info = DealerInfo.new
      @dealer_info.start_time = "0001-01-01 09:00".to_time
      @dealer_info.end_time = "0001-01-01 21:00".to_time
      @dealer_info.destination_website = "http://"
#    else
#      @dealer_info
#    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @dealer_info }
    end
  end

  # POST /dealer_infos
  # POST /dealer_infos.xml
  def create
    @dealer_info = DealerInfo.new(params[:dealer_info])

    respond_to do |format|
      if @dealer_info.save
        format.html { redirect_to(:action => 'thank_you', :notice => 'Dealer info was successfully created.') }
        format.xml  { render :xml => @dealer_info, :status => :created, :location => @dealer_info }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @dealer_info.errors, :status => :unprocessable_entity }
      end
    end
  end
end
