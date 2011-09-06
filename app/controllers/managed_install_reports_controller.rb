class ManagedInstallReportsController < ApplicationController
  def show
    respond_to do |format|
      if @managed_install_report.nil? or @managed_install_report.computer.unit.id != current_unit.id
        format.js { render page_not_found }
      else
        format.js
      end
    end
  end
  
  private
  def load_singular_resource
    action = params[:action].to_sym
    if [:show].include?(action)
      @managed_install_report = ManagedInstallReport.where(:id => params[:id]).first
    end
  end 
end