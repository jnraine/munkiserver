class NullObject

  def self.Maybe(object)
    object.present? ? object : NullObject.new
  end
  
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
  
  def to_s
    ""
  end
end