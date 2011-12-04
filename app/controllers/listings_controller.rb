class ListingsController < ApplicationController
  before_filter :get_customer

  # GET /listings
  # GET /listings.xml
  def index
    if(request.format.to_s.match(/json/))
      @listings = Listing.where(:customer_id => @customer.id)
    else
      @listings = Listing.where(:customer_id => @customer.id).order("id DESC").limit(10)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => get_json }
    end
  end

  def sync
    if @customer
      @listings = Listing.where(:customer_id => @customer.id, :active => true, :foreign_active => true).includes(:listing_infos, :listing_images)
      data = []
      time = Time.now
      @listings.each do |listing|
        images = listing.listing_images.map(&:complete_image_url)
        infos = listing.listing_infos.map { |obj| {:key => obj.key, :value => obj.value} }
        data << listing.attributes.merge(:ad_image_urls => images, :listing_infos => infos, :location => (!listing.location.nil? ? listing.location.url : "miami"), :sublocation => (!listing.sublocation.nil? ? listing.sublocation.url : "mdc"), :ad_foreign_id => listing.foreign_id)
      end
      logger.debug "It took #{Time.now-time} to iterate through listings"
      render :json => JSON.generate(data) 
      logger.debug "Total Time: #{Time.now-time} (after JSON.generate)"
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

  def get_json
    # Columns which we need to sort in order 
    # and the are in order as they appear on view page
    columns = ['', 'updated_at', 'active', "", "", 'foreign_active']
    # add additional empty fields though no necessary cuz they are dynamic field
    # and yet can't sort or order based on keys
    columns = ['', ''] + columns if @customer.craigslist_type == "apa"
    # Sort one of the column
    params[:iSortingCols].to_i.times do |i|
      if(params["bSortable_#{i}"] == "true")
        column = columns[params["iSortCol_#{i}"].to_i]
        next if column.blank? # blank means dynamic field and can't be sorted easily need work around
        order = (column + " " + params["sSortDir_#{i}"])
        @listings = @listings.order(order)
      end
    end
    # searching 
    # this part is not used yet 
    columns.each_with_index do |column, index|
      break unless column == 'title' #  only search in title field
      next if column.blank?
      if params["bSearchable_#{index}"] == 'true' && params["sSearch_#{index}"].present?
        where = columns[index] + " LIKE '%" + params["sSearch_#{index}"] + "%'"
        @listings = @listings.where(where)
      end
    end

    # searching 
    # this part also not working fine
    if  params[:sSearch].present?
      value = params[:sSearch]
      where = ""
      orr = 0
      columns.each_with_index do |column, index|
        next if column.blank?
        column = "listings.updated_at" if column == 'updated_at'
        where << ((orr == 0) ? column + " LIKE '%" + value.to_s + "%'" : " OR " + column + " LIKE '%" + value.to_s + "%'")
        orr += 1
      end
      @listings = @listings.where(where)
    end

    offset = params[:iDisplayStart].to_i
    limit = params[:iDisplayLength].to_i
    @data =  @listings.offset(offset).limit(limit)
    logger.debug "==========================="
    logger.debug @data.to_sql
    logger.debug "==========================="
    {
      sEcho: params[:sEcho],
      iTotalRecords: Listing.where(:customer_id => @customer.id).count,
      iTotalDisplayRecords: @listings.size,
      aaData: @data.map {|listing| 
      [
        listing.title,
        listing.updated_at.strftime("%m/%d %I:%M %p"),
        listing.active ? 'Active' : 'Inactive',
        act_de(listing),
        edit_it(listing),
        listing.foreign_active ? 'Updated' : 'Outdated'
      ]
    }
    }.to_json
  end

  def act_de(listing)
    link = '<a rel="nofollow" data-method="delete" data-confirm="Are you sure you want to stop posting this ad?" href="'
    link += "/customers/#{@customer.id}/listings/#{listing.id}" + '">' 
    link += (listing.active ? 'Deactivate' : 'Activate') + '</a>'
  end

  def edit_it(listing)

    link = '<a  href="'
    link += "/customers/#{@customer.id}/listings/#{listing.id}/edit" + '">' 
    link += (listing.active ? 'Edit' : 'Edit') + '</a>'
    return link
  end

end
