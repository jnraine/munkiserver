module HasAnEnvironment
  def self.included(base)
    base.class_eval do
      belongs_to :environment
      
      scope :environment, lambda { |p| where(:environment_id => p.id) }
      scope :environment_ids, lambda { |ids| where(:environment_id => ids) }
      scope :environments, lambda { |p| where(:environment_id => p.collect(&:id)) }
    
      validates_presence_of :environment_id
    end
  end
end