module DashboardHelper
  def render_widget(name)
    @widget = "#{name.to_s.camelize}Widget".constantize.new(current_user)
    if @widget.lazy_loading?
      render :partial => "widgets/lazy_load", :layout => "widgets/wrapper"
    else
      render :partial => @widget.partial_name, :layout => "widgets/wrapper"
    end
  end
  
  def new_package_unit_options(units)
    options_array = []
    units.each do |unit|
      options_array << [unit.to_s,packages_path(unit)] if can? :create, Package.new_for_can(unit)
    end
    options_for_select(options_array)
  end
end
