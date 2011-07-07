class Configuration < ActiveRecord::Base
  has_one :computer
  has_one :computer_group
  has_one :unit
  
  #Internally use configuration, externally use config
  serialize :configuration, Hash
  
  def owner
    return computer if computer 
    return computer_group if computer_group
    return unit if unit 
  end
  
  def parent_config
    if owner.is_a? Computer
      computer.computer_group.client_pref
    end

    if owner.is_a? ComputerGroup
      computer_group.unit.client_pref
    end

    if owner.is_a? Unit
      MunkiService.client_pref
    end
  end
  
  def resultant_config
    if inherit
      owner.parent_config.merge(self.configuration)
    else
      self.configuration
    end
  end
  
  def config
    configuration
  end
  
  def config=(config)
    configuration = config
  end
  
  def self.configuration_options
    
  end
  
  def self.configuration_helpers
    
  end
end