class ManagedInstallReportsController < ApplicationController
  before_filter :require_valid_unit
  def show
    begin
      @managed_install_report = ManagedInstallReport.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      # redirect_to root_url
    end
    respond_to do |format|
      if @managed_install_report.nil?
        redirect_to root_url
      elsif @managed_install_report.computer.unit.id != current_unit.id
        redirect_to root_url
      else
        format.js
      end
    end
  end
    
end