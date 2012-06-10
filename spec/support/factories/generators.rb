FactoryGirl.define do
  sequence(:mac_address) {|n| "ff:ff:ff:ff:ff:f#{13.to_s[-1].to_i}" }
end