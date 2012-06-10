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
  
  factory :package do
    unit
    environment
    installer_item_location { "foo" }
    version { "1.0" }
    package_branch
  end
  
  factory :package_branch do
    unit
    package_category
    sequence(:name) {|n| "package_branch_#{n}" }
    sequence(:display_name) {|n| "Package Branch #{n}" }
  end
  
  factory :package_category do
    sequence(:name) {|n| "Package Category #{n}" }
    description "Description"
  end
end