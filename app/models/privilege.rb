class Privilege < ActiveRecord::Base
  validates :name, :presence => true
  
  has_many :permissions
  has_many :units, :through => :permissions
  has_many :principals, :through => :permissions
  
  scope :unit_specific, where(:unit_specific => true)
  scope :unit_nonspecific, where(:unit_specific => false)
  
  def action
    @action ||= name.match(/^([a-z]+)_([a-z_]+)$/)[1]
  end
  
  def action_target
    @action_target ||= name.match(/^([a-z]+)_([a-z_]+)$/)[2]
  end
  
  def to_s
    name
  end
end
