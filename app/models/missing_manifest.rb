class MissingManifest < ActiveRecord::Base
  # Include helpers
  include ActionView::Helpers

  scope :recent, lambda {|timestamp,limit| 
    scope = MissingManifest.scoped
    if timestamp.present?
      scope = scope.where("created_at > ?", timestamp)
    else
      MissingManifest.where("created_at > ?", 7.days.ago)
    end
    scope = scope.limit(limit) if limit.present?
    scope.order("created_at DESC")
  }
  
  def request_ip=(value)
    self.hostname = get_hostname(value)
    super(value)
  end
  
  def get_hostname(ip)
    Socket.gethostbyaddr(ip.split(".").map(&:to_i).pack("CCCC")).first
  end
  
  def request_time
    s = nil
    if created_at > 12.hours.ago
			s = time_ago_in_words(created_at) + " ago"
		else
		  s = created_at.getlocal.to_s(:readable_detail)
		end
		s
  end
end

