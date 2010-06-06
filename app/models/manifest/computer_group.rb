class ComputerGroup < ActiveRecord::Base
  magic_mixin :manifest
  has_many :computers

  # Tabled ASM select hash for adding computers to the group
  def computers_tas
    # Get all the package branches associated with this unit and environment
    computer_options = Computer.unit_member(self).map {|e| [e.name, e.id]}
    model_name = self.to_s.underscore

    # Array for table_asm_select
    [{:title => "Members",
      :model_name => model_name,
      :attribute_name => "computers",
      :select_title => "Select a computer",
      :options => computer_options,
      :selected_options => self.computer_ids }]
  end
  
  # Extend the destroy method to not destroy the last one in that unit
  def destroy
    if ComputerGroup.find_all_by_unit_id(self.unit_id).count == 1
      raise ComputerGroupException.new("Attempt to remove last computer group in unit failed!")
    else
      super
    end
  end
  # Every ComputerGroup has the first environment  
  before_validation { self.environment = Environment.first }
end

class ComputerGroupException < Exception
end