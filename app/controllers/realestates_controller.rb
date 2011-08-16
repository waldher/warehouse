class RealestatesController < ApplicationController
  # GET /realestates
  # GET /realestates.xml
  def index
    @realestates = Realestate.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @realestates }
    end
  end

  # GET /realestates/1
  # GET /realestates/1.xml
  def show
    @realestate = Realestate.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @realestate }
    end
  end

  # GET /realestates/new
  # GET /realestates/new.xml
  def new
    @realestate = Realestate.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @realestate }
    end
  end

  # GET /realestates/1/edit
  def edit
    @realestate = Realestate.find(params[:id])
  end

  # POST /realestates
  # POST /realestates.xml
  def create

    
    @realestate = Realestate.new(params[:realestate])

    respond_to do |format|
      if @realestate.save
        format.html { redirect_to(@realestate, :notice => 'Realestate was successfully created.') }
        format.xml  { render :xml => @realestate, :status => :created, :location => @realestate }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @realestate.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /realestates/1
  # PUT /realestates/1.xml
  def update
    @realestate = Realestate.find(params[:id])

    respond_to do |format|
      if @realestate.update_attributes(params[:realestate])
        format.html { redirect_to(@realestate, :notice => 'Realestate was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @realestate.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /realestates/1
  # DELETE /realestates/1.xml
  def destroy
    @realestate = Realestate.find(params[:id])
    @realestate.destroy

    respond_to do |format|
      format.html { redirect_to(realestates_url) }
      format.xml  { head :ok }
    end
  end
end
