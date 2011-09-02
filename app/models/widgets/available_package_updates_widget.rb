class AvailablePackageUpdatesWidget < DashboardWidget
  # Return a hash of available package updates for each unit the user belongs to
  # key => Unit name
  # value => an array of Packages with updates
  def recent_package_update_for_unit(interval = nil)
    interval ||= 7
    available_package_units = {}
    scoped_units.each do |unit|
      available_package_units[unit.name.parameterize.underscore.to_sym] = PackageBranch.available_updates(unit)
    end
    available_package_units
  end
end