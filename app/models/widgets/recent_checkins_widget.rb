class RecentCheckinsWidget < DashboardWidget
  # Return a hash contains each unit's checkin
  # key => Unit name
  # value => an array of how many computers that have checked-in in the past "interval" days
  # each index of an array represent how many computers checked-in on one day
  def checkins_by_unit(start_date)
    
    checkins_by_unit = {}
    user_units.each do |unit|
      checkins_by_unit[unit.to_s] = ManagedInstallReport.cached_checkins_between(:start_date => start_date, :end_date => Date.today, :unit => unit)
    end
    
    # Add total for all units
    total_checkins = []
    checkins_by_unit.each do |unit_name,checkins|
      checkins.each_with_index do |checkin_count,i|
        total_checkins[i] ||= 0
        total_checkins[i] += checkin_count
      end
    end

    checkins_by_unit["Total"] = total_checkins
    checkins_by_unit
  end
  
  def checked_in?(computer,date)
    computer.managed_install_reports.checkins_on_date(date)
  end
  
  # Add the key :total and the sum of all the array to the hash
  # def checkins(interval)
  #   checkins_by_unit = recent_computer_checkins_for_unit(interval)
  #   checkins = checkins_by_unit.values
  #   checkin_sums = []
  #   checkins.each do |unit_checkin|
  #    interval.times do |i|
  #      checkin_sums[i] ||= 0
  #      checkin_sums[i] += unit_checkin[i]
  #    end
  #   end
  #   checkins_by_unit["Total"] = checkin_sums
  #   checkins_by_unit
  # end

  # Data parsed by highcharts library for rendering graphic charts
  def to_highcharts(start_date = nil)
    start_date ||= 60.days.ago.to_date
    series = []
    checkins_by_unit(start_date).each do |unit_name, checkins|
      series << {:name => unit_name, :data => checkins, :pointStart => start_date.to_time.to_i*1000, :pointInterval => 1.day * 1000}
    end
    # Ready parse by highcharts
    series.to_json.html_safe
  end
  
  def lazy_loading?
    true
  end
end