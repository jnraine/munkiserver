class AvailablePackageUpdatesWidget < DashboardWidget
  # Return a hash of available package updates for each unit the user belongs to
  # key => Unit name
  # value => an array of Packages with updates
  def package_hash
    package_hash = {}
    scoped_units.each do |unit|
      updates = PackageBranch.available_updates(unit)
      package_hash[unit.name] = updates if updates.present?
    end
    package_hash
  end
end