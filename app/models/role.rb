class Role < ActiveRecord::Base
  
  has_many :assignments
  has_many :users, :through => :assignments 
  
  validates_presence_of :name
  validates_uniqueness_of :name, :message => "must be unique"

  def to_sym
    name.downcase.tr(' ', '_').to_sym
  end

end
