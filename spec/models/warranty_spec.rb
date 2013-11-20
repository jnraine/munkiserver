require 'spec_helper'

describe Warranty do
  describe "readable dates" do
    it "returns readable dates when they are set" do
      warranty = Warranty.new.tap do |w|
        w.purchase_date = Time.parse("January 1, 2000")
        w.updated_at = Time.parse("January 1, 2000")
      end

      warranty.readable_purchase_date.should == "January 01, 2000"
      warranty.readable_updated_at.should == "January 01, 2000"
    end

    it "returns 'unknown' when attributes are nil" do
      warranty = Warranty.new
      warranty.readable_purchase_date.should == "Unknown"
      warranty.readable_updated_at.should == "Unknown"
    end
  end
end