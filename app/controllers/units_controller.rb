class UnitsController < ApplicationController
  def index
    @units = Unit.all
  end

  def new
  end

  def create
    respond_to do |format|
      if @unit.update_attributes(params[:unit])
        flash[:notice] = "#{@unit.name} was successfully created."
        format.html { redirect_to(units_path) }
      else
        flash[:error] = "Failed to create #{@unit.name} unit!"
        format.html { render :action => "new" }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @unit.update_attributes(params[:unit])
        flash[:notice] = "#{@unit} was successfully updated."
        format.html { redirect_to units_path }
      else
        flash[:error] = 'Could not update unit!'
        format.html { render edit_unit_path(@unit) }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @unit.destroy
        flash[:notice] = "#{@unit} was successfully remove"
        format.html { redirect_to units_path }
      else
        flash[:error] = "Failed to removed #{@unit}!"
        format.html { render units_path }
      end
    end
  end
  
  private
  def load_singular_resource
    action = params[:action].to_sym
    if [:show, :edit, :update, :destroy].include?(action)
      @unit = Unit.find_by_shortname(params[:id])
    elsif [:index].include?(action)
      # Don't load resource
    elsif [:new, :create].include?(action)
      @unit = Unit.new
    else      
      raise Exception.new("Unable to load singular resource for #{action} action in #{params[:controller]} controller.")
    end
  end
end