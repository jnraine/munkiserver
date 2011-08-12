module SharedPackagesHelper
	def shared_package_table(packages, unit)
	  packages = packages.where(:unit_id => unit.id)
    package_branches = []
    packages.each do |p|
      package_branches << PackageBranch.find(p.package_branch_id)
    end
    render :partial => 'shared_package_table', :locals => {:packages => packages, :package_branches => package_branches.uniq, :unit => unit}
  end
end