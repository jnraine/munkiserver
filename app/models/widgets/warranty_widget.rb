class WarrantyWidget < DashboardWidget
  def expiring(options = {})
    default_options = {:expire_before => 90.days.from_now, :limit => 20, :force_query => false}
    options = default_options.merge(options)
    if @expiring.nil? or options[:force_query]
      # Find all the warranty that belong to all the units of the current user
      @expiring = Warranty.belong_to_unit(user_units).expire_before(options[:expire_before]).expire_after(Date.today)
    end
    @expiring
  end
end