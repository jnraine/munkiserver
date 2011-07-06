class InstallItemsController < ApplicationController
  before_filter :require_valid_unit
  def edit_multiple
    begin
      @computer = Computer.unit(current_unit).find(params[:computer_id])
    rescue ActiveRecord::RecordNotFound
      @install_items = []
    end
    @install_items = @computer.install_items unless @computer.nil?
    
    respond_to do |format|
      format.js
    end
  end
  
  # To-do, anyone could change the values of an install item, there is no scoping of results
  def update_multiple
    @install_items = InstallItem.update(params[:install_items].keys, params[:install_items].values).reject { |it| it.errors.empty? }  
    if @install_items.empty?   
      flash[:notice] = "Install items updated"  
      # redirect_to show_computer_path(params[:computer_id])  
      redirect_to :back
    else  
      flash[:errors] = "Some install items were not updated"
      # redirect_to show_computer_path(params[:computer_id])
      redirect_to :back
    end
  end
end
