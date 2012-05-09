module ComputersHelper
  
  # Builds a computer page (show/edit) header from a computer object
  def computer_header(computer)
    render :partial => 'shared/record_header', :locals => {:title => computer,
                              														 :img => computer.icon,
                              														 :soft_info => computer.computer_group,
                              														 :bold_info => computer.mac_address }
	end

  # Prints a computer table listing
  # Is paginated by default using will_paginate.  Pass false to disable.
  def computer_table(computers, paginate = true, batch_actions = true)
    render :partial => 'computers/computer_table', :locals => {:computers => computers, :paginate => paginate, :batch_actions => batch_actions}
  end

	def computer_group_links
    computer_groups = ComputerGroup.unit(current_unit)
    unless computer_groups.empty?
      render :partial => 'computer_group_link', :collection => computer_groups
    else
      render :text => "None"
    end
  end
  
  def render_computer_group_header(id)
    string = ''
    cg = []
    
    if id.nil?
      string = "<h3>All</h3>"
    else
      cg = ComputerGroup.of_unit(current_unit_id).find(id)
      unless cg.nil?
        string = "<h3>#{cg.name}</h3>"
      end
    end
  
    concat(render :text => string, :layout => false)
  end
  
  # Returns options tags for computer groups 
  def computer_group_options
    options_for_select(ComputerGroup.unit(current_unit).collect {|cg| [cg.name, cg.id] })
  end
  
  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"
    link_to title, params.merge({:sort => column, :direction => direction, :page => nil}), {:class => css_class}
  end
end
