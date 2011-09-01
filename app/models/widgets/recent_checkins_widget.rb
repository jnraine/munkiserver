class RecentCheckinsWidget < DashboardWidget
  # Return an array of number of checked in computer in the last 30 days
  def recent_computer_checkins(intervel = nil)
    checkins = []
    intervel ||= 30
    intervel.days.ago.to_date.step(Time.now.to_date, 1.day) do |d|
      checkins << ManagedInstallReport.where(:computer_id => scope_to_user).where('created_at >= ? and created_at <= ?', d.beginning_of_day, d.end_of_day).map(&:manifest_name).compact.uniq.count
    end
    checkins
  end
  
  def self.last_weeks
  end
  
  def self.last_month
  end
  
  def scope_to_user
    Computer.where(:unit_id => @user.units).map(&:id)
  end
end