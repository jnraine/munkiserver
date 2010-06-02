# Define module that extends ActiveRecord::Base
module ActiveRecordClassMethods
  # Converts YAML stored in DB as hash, if nil or blank, returns empty hash
  def attr_is_hash(attribute)
    # Getter for objects
    define_method attribute.to_s do
      value = read_attribute(attribute).from_yaml
      if value.nil? or value.blank?
        {}
      else
        value
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
  
  # Takes a module and calls the extend_class method, passing in 
  # self as the argument. This essentially extends the class 
  # definition for self using an class_exec method call.
  def magic_mixin(mod)
    # Add the passed module to the inherits_from class variable
    inherits_from = nil
    begin
      inherits_from = self.class_variable_get("@@inherits_from")
    rescue NameError
      inherits_from ||= []
    end
    inherits_from << mod.to_sym
    self.class_variable_set(:@@inherits_from,inherits_from)
    
    # Do the actually class extension using class_exec
    self.class_exec do
      # Grab the module name from the last entry of inherits_from
      # class variable.  This is done because class_exec doesn't
      # include the calling methods local variables.
      @@current_mod = @@inherits_from.last
      @@current_mod.to_s.classify.constantize.extend_class(self)
    end
  end
end

# Extend ActiveRecord::Base with modules
class ActiveRecord::Base
  extend ActiveRecordClassMethods
end