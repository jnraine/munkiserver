class ComputerModel < ActiveRecord::Base
  has_many :computers
  belongs_to :icon
  
  def self.default
    self.find_by_name("Default")
  end
end
