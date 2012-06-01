# Special ActiveRecord::Base mixin module
module IsAUnitMember
  # Used to augment the class definition
  # of the class passed as an argument
  # Put class customization in here!
  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      has_one :icon, :as => :record
    
      belongs_to :unit
      belongs_to :environment
    
      scope :unit, lambda { |u| u.present? ? where(:unit_id => u.id) : where(:unit_id => nil) }
      scope :environment, lambda { |p| where(:environment_id => p.id) }
      scope :environment_ids, lambda { |ids| where(:environment_id => ids) }
      scope :environments, lambda { |p| where(:environment_id => p.collect(&:id)) }
      scope :unit_and_environment, lambda { |u,e| where(:unit_id => u.id, :environment_id => e.id) }
    
      validates_presence_of :environment_id
      validates_presence_of :unit_id
    end
  end

  module ClassMethods
    # Returns a list of type self that belong to the same unit and environment as unit_member
    def unit_member(unit_member)
      self.unit(unit_member.unit).environments([unit_member.environment])
    end
  
    # Instatiates a new object, belonging to unit.  Caches for future calls.
    def new_for_can(unit)
      raise ArgumentError.new("Unit passed to new_for_can is nil") if unit.nil?
      @new_for_can ||= []
      @new_for_can[unit.id] ||= self.new(:unit => unit)
    end
  end
  
  # Array of catalogs this unit member belongs to
  def catalogs
    ["#{unit.id}-#{environment}.plist"]
  end
end