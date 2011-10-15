module Principal
  # For nested association deletion, default to false
  def _destroy
    false
  end
  
  def css_class
    self.class.to_s.underscore.gsub("_","-") + "-principal"
  end
  
  # Returns a unique principal ID for this principal
  def principal_id
    self.class.to_s + "-#{id}"
  end
end