class RecentCheckinsWidget < DashboardWidget
  # Return a hash contains each unit's checkin
  # key => Unit name
  # value => an array of how many computers that have checked-in in the past "interval" days
  # each index of an array represent how many computers checked-in on one day
  def checkins(interval = nil)
    checkin_hash = {}
    interval ||= 30
    checkin_array = []
    interval.days.ago.to_date.step(Time.now.to_date, 1.day) do |d|
      checkin_array << ManagedInstallReport.checkins_on_date(d)
    end
    checkin_hash["Total"] = checkin_array
    checkin_hash
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
  def to_highcharts(interval = nil)
    interval ||= 30
    series = []
    checkins(interval).each do |k, v|
      series << {:name => k, :data => v, :pointStart => interval.days.ago.to_i * 1000, :pointInterval => 1.day * 1000}
    end
    # Ready parse by highcharts
    series.to_json.html_safe
  end
end