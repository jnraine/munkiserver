class RecentInstallErrorsAndWarningsWidget < DashboardWidget
  # include ActionView::Helpers::UrlHelper
  
  def recent_install_errors
    ManagedInstallReport.where("munki_errors != ?", [].to_yaml)
  end
  
  def recent_install_warnings
    ManagedInstallReport.where("munki_warnings != ?", [].to_yaml)
  end
  
  def hostname
    
  end
end