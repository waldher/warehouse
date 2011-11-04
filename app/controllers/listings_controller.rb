class ListingsController < ApplicationController
  before_filter :get_customer

  # GET /listings
  # GET /listings.xml
  def index
    @listings = Listing.where(:customer_id => @customer.id).includes(:listing_infos)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def sync
    if @customer
      @listings = Listing.where(:customer_id => @customer.id, :active => true, :foreign_active => true)
      .includes(:listing_infos, :listing_images)
      data = []
      time = Time.now
      @listings.each do |listing|
        images = listing.listing_images.map(&:complete_image_url)
        infos = listing.listing_infos.map { |obj| {:key => obj.key, :value => obj.value} }
        data << listing.attributes.merge(:ad_image_urls => images, :listing_infos => infos)
      end
      logger.debug "It took #{Time.now-time}"
      render :json => JSON.generate(data) 
      logger.debug "Total Time: #{Time.now-time}"
      #render :json => @listings.to_json(
      #  :include => { :listing_infos => {:except => [:created_at, :updated_at, :id, :listing_id]} },
      #  :methods => :ad_image_urls )
    else
      render :json => []
    end
  end

  def image_update
    logger.debug params
    listing = Listing.find(params[:id])
    logger.debug params[:threading]
    listing.listing_images.each_with_index do |item, index|
      logger.debug "Replacing #{item.threading} with #{params[:threading][index]}"
      item.update_attribute(:threading, params[:threading][index])
    end
    render :text => params
  end

  # GET /listings/1
  # GET /listings/1.xml
  def show
    @listing = Listing.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @listing }
    end
  end

  # GET /listings/new
  # GET /listings/new.xml
  def new
    @listing = Listing.new
    @listing.listing_images.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @listing }
    end
  end

  # GET /listings/1/edit
  def edit
    @listing = Listing.find(params[:id])
  end

  # POST /listings
  # POST /listings.xml
  def create
    @listing = Listing.new(params[:listing])
    @listing.customer_id = @customer.id

    @listing.infos = params[:listing][:infos]


    respond_to do |format|
      if @listing.save
        format.html { redirect_to(customer_listings_path, :notice => 'Listing was successfully created.') }
        format.xml  { render :xml => @listing, :status => :created, :location => @listing }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @listing.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /listings/1
  # PUT /listings/1.xml
  def update
    @listing = Listing.find(params[:id])
    @listing.customer_id = @customer.id

    respond_to do |format|
      if @listing.update_attributes(params[:listing])
        format.html { redirect_to(customer_listings_path, :notice => 'Listing was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @listing.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /listings/1
  # DELETE /listings/1.xml
  def destroy
    @listing = Listing.find(params[:id])
    @listing.update_attributes(:active => !@listing.active)

    respond_to do |format|
      format.html { redirect_to(customer_listings_url(@customer)) }
      format.xml  { head :ok }
    end
  end

  private

  def get_customer
    if params[:customer_id]
      @customer = Customer.find(params[:customer_id])
    elsif params[:key]
      @customer = Customer.find_by_key(params[:key])
    end
  end
end
