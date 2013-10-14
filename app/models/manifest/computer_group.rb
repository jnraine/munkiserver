class ComputerGroup < ActiveRecord::Base
  include IsAManifest
  include HasAUnit
  include HasAnEnvironment
  
  has_many :computers
  
  default_scope order(:name, :environment_id)
  
  # Tabled ASM select hash for adding computers to the group
  def computers_tas(environment_id = nil)
    # Get all the package branches associated with this unit and environment
    environment_id ||= self.environment_id
    environment = Environment.where(:id => environment_id).first
    environment ||= Environment.start
    computer_options = Computer.unit(self.unit).environment(environment).map {|e| [e.name, e.id]}
    model_name = self.class.to_s.underscore

    # Array for table_asm_select
    [{:title => "Members",
      :model_name => model_name,
      :attribute_name => "computer_ids",
      :select_title => "Select a computer",
      :options => computer_options,
      :selected_options => self.computer_ids }]
  end
  
  # Reture a list of computer groups that are blong to the unit and environment
  def self.unit_and_environment(unit,environment_id)
    environment = Environment.find(environment_id)
    # if passed in unit id
    if unit.instance_of?(Fixnum)
      u = Unit.find(unit)
      ComputerGroup.unit(u).environment(environment)
    else
      ComputerGroup.unit(unit).environment(environment)
    end
  end
end

class ComputerGroupException < Exception
end
