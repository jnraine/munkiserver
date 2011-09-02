class RecentInstallErrorsWidget < DashboardWidget

  def recent_install_errors
    ManagedInstallReport.where("munki_errors != ?", [].to_yaml)
  end
  
  def hostname
    
  end
end