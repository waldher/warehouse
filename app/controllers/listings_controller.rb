require 'csv'

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
      # ("listings"."manual_enabled" = 't' OR "listings"."manual_enabled" IS NULL AND "listings"."foreign_active" = 't')
      t = Listing.arel_table
      query = t[:manual_enabled].eq(true).or(t[:manual_enabled].eq(nil).and(t[:foreign_active].eq(true)))
      @listings = Listing.where(:customer_id => @customer.id).where(query).
        select("*,
          array(select key from listing_infos where listing_id = listings.id order by key) as info_keys_array,
          array(select value from listing_infos where listing_id = listings.id order by key) as info_values_array,
          array(select complete_image_url from listing_images where listing_id = listings.id) as images_array,
          array_to_string(array(SELECT DISTINCT craigslist_keywords.spelling FROM craigslist_keywords WHERE craigslist_keywords.spelling IN (
                  SELECT spelling
                  FROM words
                  WHERE definition_id IN (
                      SELECT DISTINCT definition_id
                      FROM words
                      WHERE spelling IN (
                          SELECT unnest(string_to_array(replace(replace(replace(replace(replace(replace(lower(value), '.', ' '), ',', ' '), '&', ' '), '!', ' '), '(', ' '), ')', ' '), ' '))
                          FROM listing_infos
                          WHERE listing_id = listings.id
                            AND KEY = 'ad_description'
                          )
                      )
                  )), ' ') AS autokeywords 
        ")
      data = []
      time = Time.now
      @listings.each do |listing|
        data << listing.attributes.merge(
          :active => listing.active,
          :ad_image_urls => CSV.parse(listing.images_array[1..-2]), 
          :ad_autokeywords => listing.autokeywords,
          :listing_infos => Hash[CSV.parse(listing.info_keys_array[1..-2]).first.zip CSV.parse(listing.info_values_array[1..-2]).first], 
          :location => ((listing.location and listing.location.url) or (listing.customer.location and listing.customer.location.url) or "miami"), 
          :sublocation => ((listing.sublocation and listing.sublocation.url) or (listing.customer.sublocation and listing.customer.sublocation.url) or "mdc"), 
          :ad_foreign_id => listing.foreign_id
        )
      end
      render :json => JSON.generate(data) 
      #render :json => @listings.to_json(
      #  :include => { :listing_infos => {:except => [:created_at, :updated_at, :id, :listing_id]} },
      #  :methods => :ad_image_urls )
    else
      render :json => []
    end
  end

  def image_update
    listing = Listing.find(params[:id])
    objects = []
    params[:threading].each_with_index do |item, index|
      img = listing.listing_images.where(:threading => item.to_i).first
      img.threading = index + 1
      objects << img
    end

    objects.each do |object|
      object.save
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
    @listing.infos = get_attributes

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
    params[:listing][:infos] = get_attributes

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
    @listing.toggle!(:manual_enabled)

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
    columns = ['', 'updated_at', 'manual_enabled', "", ""]
    # add additional empty fields though no necessary cuz they are dynamic field
    # and yet can't sort or order based on keys
    columns = ['', ''] + columns if @customer.craigslist_type == "apa" || @customer.craigslist_type == 'rea'
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
    datatable_data = {
      sEcho: params[:sEcho],
      iTotalRecords: Listing.where(:customer_id => @customer.id).count,
      iTotalDisplayRecords: @listings.size,
      aaData: []
    }

    aaData = []
    if @customer.craigslist_type == "apa" || @customer.craigslist_type == 'rea'
      aaData =  @data.map {|listing| 
      [
        listing.infos["ad_address"],
        listing.infos["ad_price"],
        view_context.truncate(listing.title.join(", "), :radius => 25),
        listing.updated_at.strftime("%m/%d %I:%M %p"),
        listing.active ? 'Active' : 'Inactive',
        act_de(listing),
        edit_it(listing),
      ]
    }
    else
      aaData =  @data.map {|listing| 
      [
        listing.title,
        listing.updated_at.strftime("%m/%d %I:%M %p"),
        listing.active ? 'Active' : 'Inactive',
        act_de(listing),
        edit_it(listing),
      ]
    }
    end
    
    datatable_data.merge({aaData: aaData})
  end

  def act_de(listing)
    link = '<a rel="nofollow" data-method="delete" '
    unless listing.manual_enabled.nil?
      link += 'data-confirm="Are you sure you want to ' + (listing.manual_enabled ? "stop" : "start") +  ' posting this ad?"'
    end
    link += "href=/customers/#{@customer.id}/listings/#{listing.id}" + '">' 
    link += (listing.manual_enabled ? 'Deactivate' : 'Activate') + '</a>'
  end

  def edit_it(listing)

    link = '<a  href="'
    link += "/customers/#{@customer.id}/listings/#{listing.id}/edit" + '">' 
    link += (listing.manual_enabled ? 'Edit' : 'Edit') + '</a>'
    return link
  end

  def get_attributes
    titles_ary = []
    titles = params[:listing][:infos].delete(:ad_title)
    if titles
      titles.each { |key, value| titles_ary << value }
    end
    titles_ary.select! { |item| item.present? }
    params[:listing][:infos][:ad_title] = titles_ary
    params[:listing][:infos]
  end

end
