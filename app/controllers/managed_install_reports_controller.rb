class ManagedInstallReportsController < ApplicationController
  def show
    @managed_install_report = ManagedInstallReport.find(params[:id])
    respond_to do |format|
      format.js
    end
  end
end
