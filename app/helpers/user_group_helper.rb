module UserGroupHelper
  def principal_list_item(principal, opts={})
    render :partial => 'principal_list_item', :locals => {:principal => principal, :disabled => opts[:disabled]}
  end
end
