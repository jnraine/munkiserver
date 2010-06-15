# Special ActiveRecord::Base mixin module
module UnitMember
  # Used to augment the class definition
  # of the class passed as an argument
  # Put class customization in here!
  def self.extend_class(k)
    k.class_exec do
      # ====================
      # = Code start here! =
      # ====================
      
      has_one :icon, :as => :record
      
      belongs_to :unit
      belongs_to :environment
      
      scope :unit, lambda { |u| where(:unit_id => u.id) }
      scope :environment, lambda { |p| where(:environment_id => p.id) }
      scope :environment_ids, lambda { |ids| where(:environment_id => ids) }
      scope :environments, lambda { |p| where(:environment_id => p.collect(&:id)) }
      
      validates_presence_of :environment_id
      validates_presence_of :unit_id
      
      # Returns a list of type self that belong to the same unit and environment as unit_member
      def self.unit_member(unit_member)
        self.unit(unit_member.unit).environments([unit_member.environment])
      end
      
      # ===================
      # = Code ends here! =
      # ===================
    end
  end
end