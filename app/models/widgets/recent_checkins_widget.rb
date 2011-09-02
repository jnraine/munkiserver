class RecentCheckinsWidget < DashboardWidget
  # Return a hash contains each unit's checkin
  # key => Unit name
  # value => an array of how many computers that have checked-in in the past "interval" days
  # each index of an array represent how many computers checked-in on one day
  def recent_computer_checkins_for_unit(interval = nil)
    checkin_hash = {}
    interval ||= 30
    scoped_units.each do |unit|
      checkin_array = []
      interval.days.ago.to_date.step(Time.now.to_date, 1.day) do |d|
        checkin_array << ManagedInstallReport.where(:computer_id => scoped_computers(unit.id).map(&:id)).where('created_at >= ? and created_at <= ?', d.beginning_of_day, d.end_of_day).map(&:manifest_name).compact.uniq.count
      end
      checkin_hash[unit.name] = checkin_array
    end
    checkin_hash
  end
  
  # Add the key :total and the sum of all the array to the hash
  def total_checkins(interval)
    checkins_by_unit = recent_computer_checkins_for_unit(interval)
    
    checkins = checkins_by_unit.values
    checkin_sums = []
    checkins.each do |unit_checkin|
     (interval+1).times do |i|
       checkin_sums[i] ||= 0
       checkin_sums[i] += unit_checkin[i]
     end
    end
    checkins_by_unit["Total"] = checkin_sums
    checkins_by_unit
  end

  # Data parsed by highcharts library for rendering graphic charts
  def to_highcharts(interval = nil)
    interval ||= 30
    series = []
    total_checkins(interval).each do |k, v|
      series << {:name => k, :data => v, :pointStart => interval.days.ago.to_i * 1000, :pointInterval => 1.day * 1000}
    end
    # Ready parse by highcharts
    series.to_json.html_safe
  end
end