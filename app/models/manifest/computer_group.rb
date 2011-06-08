class ComputerGroup < ActiveRecord::Base
  magic_mixin :manifest
  magic_mixin :client_pref
  
  has_many :computers
  

  # Tabled ASM select hash for adding computers to the group
  def computers_tas
    # Get all the package branches associated with this unit and environment
    computer_options = Computer.unit_member(self).map {|e| [e.name, e.id]}
    model_name = self.class.to_s.underscore

    # Array for table_asm_select
    [{:title => "Members",
      :model_name => model_name,
      :attribute_name => "computer_ids",
      :select_title => "Select a computer",
      :options => computer_options,
      :selected_options => self.computer_ids }]
  end
  
  # Extend environment_id attribute setter
  # => When changing the environment, change the environment of all the members as well
  def environment_id=(value)
    computers.each do |c|
      c.environment_id = value
      c.save
    end
    super(value)
  end
  
  def to_param
    name
  end
end

class ComputerGroupException < Exception
end
