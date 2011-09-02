class MissingManifestsWidget < DashboardWidget
  # Get missing manifests for display in the widget
  def missing_manifests(options = {})
    default_options = {:since_time => 7.days.ago, :limit => 5, :force_query => false}
    options = default_options.merge(options)
    if @missing_manifests.nil? or options[:force_query]
      @missing_manifests = MissingManifest.recent(options)
    end
    @missing_manifests
  end
end