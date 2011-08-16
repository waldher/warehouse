class RealatorsController < ApplicationController
  # GET /realators
  # GET /realators.xml
  def index
    @realators = Realtor.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @realators }
    end
  end

  # GET /realators/1
  # GET /realators/1.xml
  def show
    @realator = Realtor.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @realator }
    end
  end

  # GET /realators/new
  # GET /realators/new.xml
  def new
    @realator = Realtor.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @realator }
    end
  end

  # GET /realators/1/edit
  def edit
    @realator = Realtor.find(params[:id])
  end

  # POST /realators
  # POST /realators.xml
  def create
    @realator = Realtor.new(params[:realtor])
    @realator.realtor_key = params[:realtor][:name]
    @realator.save!
    

    respond_to do |format|
      if @real_estate.save
        format.html { redirect_to(:action => :index, :notice => 'Realator was successfully created.') }
        format.xml  { render :xml => @realator, :status => :created, :location => @realator }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @realator.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /realators/1
  # PUT /realators/1.xml
  def update
    @realator = Realator.find(params[:id])

    respond_to do |format|
      if @realator.update_attributes(params[:realator])
        format.html { redirect_to(@realator, :notice => 'Realator was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @realator.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /realators/1
  # DELETE /realators/1.xml
  def destroy
    @realator = Realator.find(params[:id])
    @realator.destroy

    respond_to do |format|
      format.html { redirect_to(realators_url) }
      format.xml  { head :ok }
    end
  end
end
