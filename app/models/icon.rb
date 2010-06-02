class Icon < ActiveRecord::Base
  has_many :packages
  has_many :computers
  has_many :bundles
  has_many :computer_groups
  has_many :computer_models
  
  has_attachment :content_type => :image,
                  :storage => :file_system,
                  :resize_to => '512x512>',
                  :thumbnails => {:large => '96x96>',
                                  :medium => '64x64>',
                                  :small => '32x32>'}
  validates_as_attachment
  
  # Make sure we have at least a default icon
  def self.generic
    self.find_by_filename("generic.png")
  end
  
  def to_s
    public_filename
  end
end
