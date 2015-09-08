# This model is used with paperclip to create file (image) attachments and assign them to other models as icons
class Icon < ActiveRecord::Base
  has_many :packages
  has_many :computer_models
  has_many :version_tracker
  # Not ready for these to have icons yet
  # has_many :computers
  # has_many :bundles
  # has_many :computer_groups
  
  has_attached_file :photo,
                    :styles => { :tiny => ["32x32#", :png], :small => ["64x64#", :png], :medium => ["128x128#", :png], :large => ["256x256#", :png] },
                    :path => ":rails_root/public/system/:attachment/:id/:style/:filename",
                    :url => "/system/:attachment/:id/:style/:filename"
  
  # A shortcut to get the url for self.photo
  def url(type = nil)
    begin
      self.photo.url(type)
    rescue NoMethodError
      nil
    end
    if self.photo.url(type)
      self.photo.url(type)
    else
      ""
    end
  end
  
  def path(type = nil)
    begin
      self.photo.path(type)
    rescue NoMethodError
      nil
    end
    if self.photo.path(type)
      self.photo.path(type)
    else
      ""
    end
  end
  
  def to_s(type = nil)
    self.url(type)
  end
end

