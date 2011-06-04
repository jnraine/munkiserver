class Environment < ActiveRecord::Base
  has_many :computers
  has_many :computer_groups
  has_many :bundles
  has_many :packages
  
  serialize :environment_ids, Array
  
  # Returns the environment that is the logical beginning
  # for new elements.  For example, given a dev, testing,
  # and production environment, dev is the starting environment
  def self.start
    e = Environment.find_by_name("Development")
    e ||= Environment.find_by_name("Testing")
    e ||= Environment.find_by_name("Staging")
    e ||= Environment.first
    e
  end

  # Get the default environment for the view layer
  def self.default_view
    e = Environment.find_by_name("Production")
    e ||= Environment.first
    e
  end
  
  # Returns an array of environments including the current environment and the environments
  # specified by the environment_ids attribute
  def environments
    environments = []
    environment_ids.each do |id|
      e = Environment.find(id)
      environments << e unless e.nil?
    end
    
    environments << self
  end
  
  # Returns an array of environment IDs including the current environment ID
  # and the array returned from the environment_ids attribute
  def included_environment_ids
    environment_ids << id
  end
  
  # A string representation of the object
  def to_s(style = nil)    
    case style
    when :unique then super
    else name
    end
  end
end

class EnvironmentNotFound < Exception
end

