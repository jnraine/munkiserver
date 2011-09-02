module DashboardHelper
  def render_widget(name)
    @widget = "#{name.to_s.camelize}Widget".constantize.new(current_user)
    render :layout => "widgets/wrapper" do
      render :partial => @widget.partial_name
    end
  end
  
  def new_package_unit_options(units)
    options_array = []
    units.each do |unit|
      options_array << [unit.to_s,packages_path(unit)]
    end
    options_for_select(options_array)
  end
end
