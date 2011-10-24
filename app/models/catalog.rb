class Catalog
  # Looks up all package items that belong to unit and environment specified and concatenates
  # the plist objects together (we end up with an Ruby array).  Need to call .to_plist to create a string
  def self.generate(unit_id, environment_id)
    environment = Environment.find(environment_id)
    
    if environment.nil?
      raise EnvironmentNotFound
    end
    
    packages = Package.where(:unit_id => unit_id, :environment_id => environment_id).to_a
    packages.map(&:serialize_for_plist)
  end
end