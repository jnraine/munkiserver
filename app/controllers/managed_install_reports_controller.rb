class ManagedInstallReportsController < ApplicationController
  before_filter :require_valid_unit
  def show
    @managed_install_report = ManagedInstallReport.find(params[:id])
    respond_to do |format|
      if @managed_install_report.computer.unit.id != current_unit.id
        render :text => "Error, could not find the computer report that belong to your unit"
      else
        format.js
      end
    end
  end
end
