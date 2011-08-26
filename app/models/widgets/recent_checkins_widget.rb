class RecentCheckinsWidget < DashboardWidget
  # Return an array of number of checked in computer in the last 30 days
  def self.recent_computer_checkins(intervel = nil)
    checkins = []
    intervel ||= 30
    intervel.days.ago.to_date.step(Time.now.to_date, 1.day) do |d|
      checkins << ManagedInstallReport.where('created_at >= ? and created_at <= ?', d.beginning_of_day, d.end_of_day).map(&:manifest_name).compact.uniq.count
    end
    checkins
  end
  
  def self.recent_days(intervel = nil)
    dates = []
    intervel ||= 30
    intervel.days.ago.to_date.step(Time.now.to_date, 1.day) do |d|
      dates << d.day
    end
    dates
  end
  
  def self.today
    today = ManagedInstallReport.where('created_at >= ? and created_at <= ?', Time.zone.now.beginning_of_day, Time.zone.now.end_of_day)
    today.map(&:manifest_name).compact.uniq.count
  end
  
  def self.last_weeks
  end
  
  def self.last_month
  end
end