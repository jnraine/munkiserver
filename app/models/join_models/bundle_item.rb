class BundleItem < ActiveRecord::Base
  belongs_to :bundle
  belongs_to :manifest, :polymorphic => true
  
  def self.destroy_stale_records
    Rails.logger.info "Destroying #{self.to_s} records with nil package reference..."
    records_with_nil_packages.map do |item|
      Rails.logger.info "Destroying item.inspect"
      item.destroy
    end
  end
  
  def self.records_with_nil_packages
    self.all.delete_if {|item| item.present? }
  end
end

