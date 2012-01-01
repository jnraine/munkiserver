FactoryGirl.define do
  factory :computer do
    name "Munki client test"
    shortname { name.downcase.lstrip.rstrip.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/,'') }
    mac_address
    environment
    unit
  end
  
  factory :environment do
    sequence(:name) {|n| "Environment #{n}" }
    description "Factory-made environment"
  end
  
  factory :unit do
    sequence(:name) {|n| "Unit #{n}" }
    shortname { name.downcase.lstrip.rstrip.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/,'') }
    description "Factory-made unit"
  end
end