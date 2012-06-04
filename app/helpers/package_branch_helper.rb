module PackageBranchHelper
  def package_branch_header(package_branch)
    render :partial => 'record_header', :locals => {:title => package_branch.display_name,
                                                           :soft_info => package_branch.name}
  end
end
