module HasAnIcon
  def self.included(base)
    base.class_eval do
      has_one :icon, :as => :record
    end
  end
end