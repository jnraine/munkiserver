class AddLastReportAtToComputer < ActiveRecord::Migration
  def self.up
    add_column :computers, :last_report_at, :datetime
  end

  def self.down
    remove_column :computers, :last_report_at
  end
end
