class RecentItemsWidget < DashboardWidget
  # Get the latest 5 computers at most recent 14 days
  def recent_new_computers(recent = nil)
    recent ||= 14
    Computer.where("created_at >= ?", recent.days.ago).limit(5)
  end
  
  def recent_new_bundles(recent = nil)
    recent ||= 14
    Computer.where("created_at >= ?", recent.days.ago).limit(5)
  end
  
  def recent_new_computer_groups(recent = nil)
    recent ||= 14
    Computer.where("created_at >= ?", recent.days.ago).limit(5)
  end
  
end