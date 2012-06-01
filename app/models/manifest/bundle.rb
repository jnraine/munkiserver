class Bundle < ActiveRecord::Base
  include IsAManifest
  include HasAUnit
  include HasAnEnvironment

  scope :order_alphabetical, order("name")
  
  def self.find_for_environment_change(id, current_unit)
    if id == "new"
      Bundle.new({:unit_id => current_unit.id})
    else
      Bundle.find(id)
    end
  end
end
