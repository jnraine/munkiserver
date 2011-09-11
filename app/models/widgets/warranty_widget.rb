class WarrantyWidget < DashboardWidget
  def expiring(options = {})
    default_options = {:expire_before => 500.days.from_now, :limit => 20, :force_query => false}
    options = default_options.merge(options)
    if @expiring.nil? or options[:force_query]
      @expiring = Warranty.expire_before(options[:expire_before])
    end
    @expiring
  end
end