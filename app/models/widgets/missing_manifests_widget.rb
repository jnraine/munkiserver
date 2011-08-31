class MissingManifestsWidget < DashboardWidget
  # Get missing manifests for display in the widget
  def self.missing_manifests(interval = nil, limit = nil)
    interval ||= interval.days.ago unless interval == nil
    interval ||= 7.days.ago
    limit ||= 5
    MissingManifest.recent(interval,limit)
  end
end