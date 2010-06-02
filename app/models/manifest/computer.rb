class Computer < ActiveRecord::Base
  magic_mixin :manifest
  
  belongs_to :computer_model
  belongs_to :computer_group
  
  validate :computer_model
  
  # Getter for virtual attribute hostname
  def hostname
    name
  end
  
  # Setting for virtual attribute hostname
  def hostname=(value)
    name = value
  end
  
  # Alias the computer_model icon to this computer
  def icon
    computer_model.icon
  end
  
  # For will_paginate gem
  def self.per_page
    10
  end
  
  # Validates the presence of a computer model
  # and puts in the default model otherwise
  def presence_of_computer_model
    if computer_model.nil?
      computer_model = ComputerModel.default
    end
  end
end
