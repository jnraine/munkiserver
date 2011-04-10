# Special ActiveRecord::Base mixin module
module ClientPref
  # Used to augment the class definition
  # of the class passed as an argument
  # Put class customization in here!
  def self.extend_class(k)
    k.class_exec do
      belongs_to :configuration

      def client_prefs
        #Unless you already have a configuration attached to you,
        #temporarily create a blank config
        (self.configuration = Configuration.new) unless self.configuration
        
        #Pass resultant_config
        self.configuration.resultant_config
      end
    end
  end
end