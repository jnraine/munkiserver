class RecentWarrantyExpireWidget < DashboardWidget
  def self.recent_warranty_expire(interval = nil, limit = nil)
    interval ||= interval
    interval ||= 90
    limit ||= 5
    recent_warranty_expire = []
    Warranty.all.each do |warranty|
      if warranty.hw_coverage_end_date < interval.days.from_now
        recent_warranty_expire << warranty
      end
    end
    recent_warranty_expire
  end
  
end