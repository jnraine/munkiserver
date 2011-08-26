class MissingManifestsWidget < DashboardWidget
  # Get missing manifests for display in the widget
  def missing_manifests
    MissingManifest.recent(7.days.ago,5)
  end
end