module StringInstanceMethods
  # Returns false if string
  # is digit zero (0), otherwise
  # returns true
  def to_bool
    self != "0"
  end
  
  # Converts a string safely from YAML 
  # (handles nil and blank values)
  def from_yaml
    results = YAML.load(self)
    
    # Replace bad values
    if results == false or results == nil
      ""
    else
      results
    end
  end
end

class String
  include StringInstanceMethods
end

class NilClass
  def from_yaml
    nil
  end
end