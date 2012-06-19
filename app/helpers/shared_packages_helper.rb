module SharedPackagesHelper
	def shared_package_table(branches)
    render :partial => 'shared_package_table', :locals => {:branches => branches}
  end
  # count the number of shared packages within a given unit
  def count_shared_packages(packages, unit)
    packages.where(:unit_id => unit.id).count
  end
end