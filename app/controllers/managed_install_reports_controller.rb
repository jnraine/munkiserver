class ManagedInstallReportsController < ApplicationController
  before_filter :require_valid_unit
  def show
    @managed_install_report = ManagedInstallReport.find(params[:id])
    respond_to do |format|
    debugger
      if !@managed_install_report.present? or (@managed_install_report.computer.unit.id != current_unit.id)
        render :text => "The report that you have requested does not exist."
      # elsif @managed_install_report.computer.unit.id != current_unit.id
      #        render :text => "Error, could not find the computer report that belong to your unit"
      else
        format.js
      end
    end
  end
end
