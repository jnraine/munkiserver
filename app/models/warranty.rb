# This was based off of a script by Gary Larizza.
# https://github.com/glarizza/scripts/blob/master/ruby/warranty.rb

require 'open-uri'
require 'openssl'

# This is a complete hack to disregard SSL Cert validity for the Apple
#  Selfserve site.  We had SSL errors as we're behind a proxy.  I'm
#  open suggestions for doing it 'Less-Hacky.' You can delete this 
#  code if your network does not have SSL issues with open-uri.
module OpenSSL
  module SSL
    remove_const:VERIFY_PEER
  end
end
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class Warranty < ActiveRecord::Base
  belongs_to :computer
  
  validates_format_of :serial_number, :with => /^[a-zA-Z0-9]+$/


  def self.get_warranty_hash(serial = "")
    if serial.blank?
      Rails.logger.warn "Blank serial number for computer #{computer}"
    end
    
    hash = {}
    begin
      open('https://selfsolve.apple.com/warrantyChecker.do?sn=' + serial.upcase) do |item|
        warranty_array = item.string.strip.split('"')
        warranty_array.each do |array_item|
          hash[array_item] = warranty_array[warranty_array.index(array_item) + 2] if array_item =~ /[A-Z][A-Z\d]+/
        end
        hash
      end
    rescue URI::Error
      computer = Computer.where(serial_number: serial)
      Rails.logger.error "Invalid serial number #{serial} for computer #{computer}"
      puts "Invalid serial number #{serial} for computer #{computer}"
    end
    
    purchase_date = Date.parse(hash['PURCHASE_DATE']) if hash['PURCHASE_DATE'].present?
    hw_coverage_end_date = Date.parse(hash['COV_END_DATE']) if hash['COV_END_DATE'].present?
    phone_coverage_end_date = Date.parse(hash['PH_END_DATE']) if hash['PH_END_DATE'].present?
    
    { serial_number:        serial, 
      product_description:  hash['PROD_DESCR'],
      product_type:         hash['PRODUCT_TYPE'],

      purchase_date:           purchase_date,
      hw_coverage_end_date:    hw_coverage_end_date,
      phone_coverage_end_date: phone_coverage_end_date,      

      registered:             hash['IS_REGISTERED'] == 'Y',
      hw_coverage_expired:    hash['HW_HAS_COVERAGE'] == 'N',
      app_registered:         hash['HW_HAS_APP'] == 'Y',
      app_eligible:           hash['IS_APP_ELIGIBLE'] == 'Y',
      phone_coverage_expired: hash['PH_HAS_COVERAGE'] == 'N',

      specs_url:            "http://support.apple.com/specs/#{serial}",
      hw_support_url:       hash['HW_SUPPORT_LINK'],
      forum_url:            hash['FORUMS_URL'],
      phone_support_url:    hash['PHONE_SUPPORT_LINK'],
    }
  end
  
  def get_status(bool)
    if bool
      "green"
    else
      "red"
    end
  end

  def registered_status
    get_status(registered)
  end
  
  def hw_coverage_status
    get_status(!hw_coverage_expired)
  end
  
  def phone_coverage_status
    get_status(!phone_coverage_expired)
  end
  
  def app_eligibility_status
    get_status(app_eligible)
  end
end
