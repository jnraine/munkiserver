class ComputerModel < ActiveRecord::Base
  has_many :computers
  belongs_to :icon
  
  def self.default
    self.find_by_name("Default")
  end
  # 
  # def self.find_by_machine_model(machine_model)
  #   self.find_by_name(machine_model_to_name(machine_model))
  # end
  # 
  # def self.machine_model_to_name(machine_model)
  #   MACHINE_MODEL_ASSC.each do |n,models|
  #     return n if models.include?(machine_model)
  #     puts "there is a bug when passing nil to this function!"
  #     debugger
  #   end
  # end
end

# == Schema Information
#
# Table name: computer_models
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  identifier :string(255)
#  icon_id    :integer
#  created_at :datetime
#  updated_at :datetime
#

