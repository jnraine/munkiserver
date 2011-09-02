class RecentInstallErrorsWidget < DashboardWidget
  # Return a hash of computers with install errors
  # key => computer name
  # values => an array of install errors
  def reports
    reports = {}
    scoped_computers.each do |computer|
      tmp_reports = computer.managed_install_reports.has_errors.since(time_period)
      reports[computer.name] = tmp_reports if tmp_reports.present?
    end
    reports
  end
  
  def time_period
    3.days.ago
  end
end