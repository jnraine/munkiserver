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
  has_many :notifications, :as => :notified
  
  validates_format_of :serial_number, :with => /^[a-zA-Z0-9]+$/
  
  scope :expire_after, lambda {|time| where("hw_coverage_end_date > ?", time)}
  scope :expire_before, lambda {|time| where("hw_coverage_end_date < ?", time)}
  scope :belong_to_unit, lambda {|unit| where(:computer_id => Computer.where(:unit_id => unit))}

  # Creates a hash used to update or create a warranty object.  Raises WarrantyException
  def self.get_warranty_hash(serial = "")
    if serial.blank?
      Rails.logger.warn "Blank serial number for computer #{computer}"
    end
    
    hash = {}
    begin
      open('https://selfsolve.apple.com/warrantyChecker.do?sn=' + serial.upcase) do |item|
        if item.string.match(/ERROR_CODE/)
          raise WarrantyException.new("Unable to retrieve warranty information for serial number #{serial.upcase}")
        end
        warranty_array = item.string.strip.split('"')
        warranty_array.each do |array_item|
          hash[array_item] = warranty_array[warranty_array.index(array_item) + 2] if array_item =~ /[A-Z][A-Z\d]+/
        end
        hash
      end
    rescue URI::Error
      computer = Computer.where(:serial_number => serial)
      Rails.logger.error "Invalid serial number #{serial} for computer #{computer}"
      puts "Invalid serial number #{serial} for computer #{computer}"
    rescue SocketError
      # No internet connection return nil
    end
    
    purchase_date = Date.parse(hash['PURCHASE_DATE']) if hash['PURCHASE_DATE'].present?
    # change from COV_END_DATE to HW_END_DATE, experiencing glitches inaccurate dates from Apple using COV_END_DATE
    hw_coverage_end_date = Date.parse(hash['HW_END_DATE']) if hash['HW_END_DATE'].present?
    phone_coverage_end_date = Date.parse(hash['PH_END_DATE']) if hash['PH_END_DATE'].present?

    { :serial_number =>           serial,
      :product_description =>     hash['PROD_DESCR'],
      :product_type =>            hash['PRODUCT_TYPE'],

      :purchase_date =>           purchase_date,
      :hw_coverage_end_date =>    hw_coverage_end_date,
      :phone_coverage_end_date => phone_coverage_end_date,

      :registered =>              hash['IS_REGISTERED'] == 'Y',
      :hw_coverage_expired =>     hash['HW_HAS_COVERAGE'] == 'N',
      :app_registered =>          hash['HW_HAS_APP'] == 'Y',
      :app_eligible =>            hash['IS_APP_ELIGIBLE'] == 'Y',
      :phone_coverage_expired =>  hash['PH_HAS_COVERAGE'] == 'N',
      
      :specs_url =>               "http://support.apple.com/specs/#{serial}",
      :hw_support_url =>          hash['HW_SUPPORT_LINK'],
      :forum_url =>               hash['FORUMS_URL'],
      :phone_support_url =>       hash['PHONE_SUPPORT_LINK'],
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
  
  # Return true if warranty is about to expire in 90, 30, 15, 5 days
  def notification_due?
    notification_due = false
    if hw_coverage_end_date.present?
      planned_notification_dates.each do |planned_notice|
        if in_the_past(planned_notice) and last_notice_before(planned_notice)
          notification_due = true
          break
        end
      end
    end
    notification_due
  end
  
  # Return how many days until the warrany expires
  def days_left
    if hw_coverage_end_date.present?
      diff = hw_coverage_end_date.to_date - Time.now.to_date
      diff.to_i
    end
  end
  
  # Return an array of real dates notifications suppose to be sent, starting with the earliest
  def planned_notification_dates
    interval = [90,30,15,5]
    dates_interval = []
    interval.each do |date|
      dates_interval << hw_coverage_end_date.to_date - date
    end
    dates_interval.sort
  end
  
  def in_the_past(date)
    date < Time.now.to_date
  end
  
  def last_notice_before(date)
    @last_notice ||= notifications.map(&:created_at).sort.last
    @last_notice.nil? or @last_notice < date
  end
  
end
