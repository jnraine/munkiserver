class ComputerGroup < ActiveRecord::Base
  magic_mixin :manifest
  has_many :computers

  # Every ComputerGroup has the first environment  
  before_validation { self.environment = Environment.first }
end
