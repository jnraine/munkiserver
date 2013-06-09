# This was based off of a script by Gary Larizza & Joseph Chilcote
# https://github.com/glarizza/scripts/blob/master/ruby/warranty.rb
# https://github.com/chilcote/warranty/blob/master/warranty.rb

require 'open-uri'
require 'openssl'
require 'net/http'

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

    begin
      uri              = URI.parse('https://selfsolve.apple.com/wcResults.do')
      http             = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl     = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request          = Net::HTTP::Post.new(uri.request_uri)

      # Prepare POST data
      request.set_form_data(
        {
          'sn'       => serial,
          'Continue' => 'Continue',
          'cn'       => '',
          'locale'   => '',
          'caller'   => '',
          'num'      => '0'
        }
      )

      # POST data and get the response
      response      = http.request(request)
      response_data = response.body
      
    rescue URI::Error
      computer = Computer.where(:serial_number => serial)
      Rails.logger.error "Invalid serial number #{serial} for computer #{computer}"
    rescue SocketError
      # No internet connection return nil
    end

    begin
      snippet = serial[-3,3]
      snippet = serial[-4,4] if serial.length == 12
      prod_desc = "Could not retrieve description"
      open('http://support-sp.apple.com/sp/product?cc=' + snippet + '&lang=en_US').each do |line|
        prod_desc = line.split('Code>')[1].split('</config')[0]
      end
    rescue
      Rails.logger.warn "Could not retrieve production description for computer #{computer}"
    end

    begin
      hw_warranty_status = response_data.split('warrantyPage.warrantycheck.displayHWSupportInfo').last.split('Repairs and Service Coverage: ')[1] =~ /^Active/ ? true : false
      ph_warranty_status = response_data.split('warrantyPage.warrantycheck.displayPHSupportInfo').last.split('Telephone Technical Support: ')[1] =~ /^Active/ ? true : false
      reg_status = response_data.split('warrantyPage.setClassAndShow').last.split(';')[0].split(',').last =~ /true/ ? true : false
      hw_has_app = response_data.split('warrantyPage.warrantycheck.displayEligibilityInfo').last.split(';')[0].split(',')[2] =~ /Covered/ ? true : false
      app_eligibile_status = response_data.split('warrantyPage.warrantycheck.displayEligibilityInfo').last.split(';')[0].split(',')[2] =~ /Eligible/ ? true : false unless hw_has_app

      hw_expiration_date = response_data.split('Estimated Expiration Date: ')[1].split('<')[0] if hw_warranty_status
      ph_expiration_date = response_data.split('Estimated Expiration Date: ')[1].split('<')[0] if ph_warranty_status


      { :serial_number =>           serial,
        :product_type =>            prod_desc,

        :hw_coverage_end_date =>    hw_expiration_date,
        :phone_coverage_end_date => ph_expiration_date,

        :registered =>              reg_status == true,
        :hw_coverage_expired =>     hw_warranty_status == false,
        :app_registered =>          hw_has_app == true,
        :app_eligible =>            app_eligibile_status == true,
        :phone_coverage_expired =>  ph_warranty_status == false,

        :specs_url =>               "http://support.apple.com/specs/#{serial}",
        :hw_support_url =>          "https://expresslane.apple.com/GetSASO?sn=#{serial}",
        :phone_support_url =>       "https://expresslane.apple.com/GetproductgroupList.do?serialno=#{serial}"
      }
    rescue
      Rails.logger.error "Cannot parse web page output #{computer} with #{serial} - likely an issue with a semi-registered computer."
      {}
    end
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
