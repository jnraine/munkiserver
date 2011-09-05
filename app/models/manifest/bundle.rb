class Bundle < ActiveRecord::Base
  magic_mixin :manifest
  
  def find_for_environment_change(id, current_unit)
    if id == "new"
      Bundle.new({:unit_id => current_unit.id})
    else
      Bundle.find(id)
    end
  end
end
