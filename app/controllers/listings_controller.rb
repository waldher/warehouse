class ListingsController < ApplicationController
  before_filter :get_customer

  # GET /listings
  # GET /listings.xml
  def index
    @listings = Listing.where(:customer_id => params[:customer_id]).all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @listings }
    end
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
    @customer = Customer.find(params[:customer_id])
  end
end
