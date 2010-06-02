module ReposHelper
  def status_info(repo)
    # Interprets status hash
    # Options for status[:state]
    # => syncing - Sync is currently happening in the background
    # => synced - Sync has completed successfully
    # => failed - There was an error syncing
    status = repo.status
    short_status = nil
    long_status = nil
    case status[:state]
    when 'syncing'
      short_status = "#{status[:state].humanize}..."
      a = ["Sync started on #{status[:sync_started]}"]
      a << "Copying #{status[:items_to_copy].to_s} files" unless status[:items_to_copy].blank?
      a << "Total size: #{humanize_bytes(status[:total_size_copied])}" unless status[:total_size_copied].blank?
      long_status = a.join("<br />")
    when 'synced'
      remote_status = repo.remote_status
      if remote_status[:errors].length != 0
        short_status = remote_status[:errors].first[:short_description]
        long_status = remote_status[:errors].first[:long_description]
      elsif remote_status[:mismatched_checksums].empty? and remote_status[:missing_packages].empty?
        short_status = "#{status[:state].humanize}"
        long_status = "Last sync on #{status[:sync_finished]}"
      else
        short_status = "Unsynchronized"
        long_status = render(:partial => "sync_failed_details", :locals => {:remote_status => remote_status, :status => status})
      end
    else
      short_status = "Never synced"
    end

    render :partial => 'status_info', :locals => {:repo => repo, :short_status => short_status, :long_status => long_status}
  end
end
