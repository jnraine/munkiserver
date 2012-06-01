# Define module that extends ActiveRecord::Base
module ActiveRecordClassMethods
  # Converts YAML stored in DB as hash, if nil or blank, returns empty hash
  def attr_is_hash(attribute)
    # Getter for objects
    h = {}
    define_method attribute.to_s do
      value = read_attribute(attribute)
      if !value.nil?
        h = YAML::load(value)
        return h
      else
        {}
      end
  	end
  end
  
  # Converts YAML stored in DB as array, if nil or blank, returns empty array
  def attr_is_array(attribute)
    # Getter for objects
    define_method attribute.to_s do
      value = read_attribute(attribute).from_yaml
      if value.nil? or value.blank?
        []
      else
        value
      end
    end
  end
end

# Extend ActiveRecord::Base with modules
class ActiveRecord::Base
  extend ActiveRecordClassMethods
end