class NullObject
  def initialize(*args)
  end
  
  def nil?
    true
  end
  
  def present?
    false
  end
  
  def method_missing(method, *args)
    self
  end
end

def Maybe(object)
  object.present? ? object : NullObject.new
end