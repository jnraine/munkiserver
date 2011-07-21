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
  
  def self.get_warranty_hash(serial)
    hash = {}
    open('https://selfsolve.apple.com/warrantyChecker.do?sn=' + serial.upcase + '&country=USA') {|item|
      warranty_array = item.string.strip.split('"')
      warranty_array.each {|array_item|
        hash[array_item] = warranty_array[warranty_array.index(array_item) + 2] if array_item =~ /[A-Z][A-Z\d]+/
      }
      hash
    }
    
    ret = { serial_number:        serial, 
      product_description:  hash['PROD_DESCR'], 
      purchase_date:        Time.new(hash['PURCHASE_DATE']),
      coverage_expired:     hash['HW_HAS_COVERAGE'] == 'N',
      coverage_end_date:    Time.new(hash['COV_END_DATE']),
      hw_support_coverage:  hash['HW_SUPPORT_COV_SHORT'],
      hw_coverage_description: hash['HW_COVERAGE_DESC'],
      product_type:         hash['PRODUCT_TYPE'],
      
      image_url:            hash['PROD_IMAGE_URL'], 
      registered:           hash['IS_REGISTERED'] == 'Y',
      specs_url:            "http://support.apple.com/specs/#{serial}",
      hw_support_url:       hash['HW_SUPPORT_LINK'],
      forum_url:            hash['FORUMS_URL'],
      phone_support_url:    hash['PHONE_SUPPORT_LINK'],
    }
  end
end
