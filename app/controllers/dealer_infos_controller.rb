class DealerInfosController < ApplicationController
  # GET /dealer_infos
  # GET /dealer_infos.xml
  def index
    @dealer_infos = DealerInfo.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @dealer_infos }
    end
  end

  # GET /dealer_infos/1
  # GET /dealer_infos/1.xml
  def show
    @dealer_info = DealerInfo.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @dealer_info }
    end
  end

  # GET /dealer_infos/new
  # GET /dealer_infos/new.xml
  def new
    @dealer_info = DealerInfo.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @dealer_info }
    end
  end

  # GET /dealer_infos/1/edit
  def edit
    @dealer_info = DealerInfo.find(params[:id])
  end

  # POST /dealer_infos
  # POST /dealer_infos.xml
  def create
    @dealer_info = DealerInfo.new(params[:dealer_info])

    respond_to do |format|
      if @dealer_info.save
        format.html { redirect_to(@dealer_info, :notice => 'Dealer info was successfully created.') }
        format.xml  { render :xml => @dealer_info, :status => :created, :location => @dealer_info }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @dealer_info.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /dealer_infos/1
  # PUT /dealer_infos/1.xml
  def update
    @dealer_info = DealerInfo.find(params[:id])

    respond_to do |format|
      if @dealer_info.update_attributes(params[:dealer_info])
        format.html { redirect_to(@dealer_info, :notice => 'Dealer info was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @dealer_info.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /dealer_infos/1
  # DELETE /dealer_infos/1.xml
  def destroy
    @dealer_info = DealerInfo.find(params[:id])
    @dealer_info.destroy

    respond_to do |format|
      format.html { redirect_to(dealer_infos_url) }
      format.xml  { head :ok }
    end
  end
end
