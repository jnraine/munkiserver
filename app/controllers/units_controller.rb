class UnitsController < ApplicationController
  before_filter :super_user?

  def index
    @units = Unit.all
  end

  def new
    @unit = Unit.new
  end

  def create
    @unit = Unit.new(params[:unit])
    
    respond_to do |format|
      if @unit.save
        flash[:notice] = "#{@unit.name} was successfully created."
        format.html { redirect_to(units_path) }
        format.xml { render :xml => @unit, :status => :created }
      else
        flash[:error] = "Failed to create #{@unit.name} unit!"
        format.html { render :action => "new"}
      end
    end
  end

  def show
    @unit = Unit.find_by_shortname(params[:id])
  end

  def edit
    @unit = Unit.find_by_shortname(params[:id])
  end

  def update
    @unit_service = UnitService.new(params)
    
    respond_to do |format|
      if @unit_service.save
        flash[:notice] = "#{@unit_service.name} was successfully updated."
        format.html { redirect_to(@unit_service.unit) }
        format.xml  { head :ok }
      else
        flash[:error] = 'Could not update unit!'
        format.html { render :action => "edit" }
        format.xml  { render :xml => @unit.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @unit = Unit.find_by_shortname(params[:id])
    unit_name = @unit.name
    unit_id = @unit.id
    
    respond_to do |format|
      if @unit.destroy
        if session[:unit_id].to_i == unit_id
          session[:unit_id] = current_user.units.first.id
          @current_unit = Unit.find(session[:unit_id])
        end
        flash[:notice] = "#{unit_name} was successfully remove"
        format.html { redirect_to(units_path) }
        format.xml { head :ok }
      else
        flash[:error] = "Failed to removed #{unit_name}!"
        format.html { render :action => "index" }
      end
    end
  end
end