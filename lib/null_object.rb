class NullObject
  def initialize(*args)
  end
  
  def nil?
    true
  end
  
  def blank?
    true
  end
  
  def present?
    false
  end
  
  def empty?
    true
  end
  
  def method_missing(method, *args)
    self
  end
  
  def self.Maybe(object)
    object.present? ? object : NullObject.new
  end
end