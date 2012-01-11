class RemoveDefaultValuesFromTextColumns < ActiveRecord::Migration
  def self.up
    ### Packages ###
    add_column :packages, :temp_receipts, :text
    add_column :packages, :temp_supported_architectures, :text
    add_column :packages, :temp_installs, :text
    add_column :packages, :temp_raw_tags, :text

    Package.find(:all).each do |p|
      p.temp_receipts = p.receipts
      p.temp_supported_architectures = p.supported_architectures
      p.temp_installs = p.installs
      p.temp_raw_tags = p.raw_tags
      p.save!
    end

    remove_column :packages, :receipts
    rename_column :packages, :temp_receipts, :receipts
    remove_column :packages, :supported_architectures
    rename_column :packages, :temp_supported_architectures, :supported_architectures
    remove_column :packages, :installs
    rename_column :packages, :temp_installs, :installs
    remove_column :packages, :raw_tags
    rename_column :packages, :temp_raw_tags, :raw_tags

    ### Computers ###
    add_column :computers, :temp_raw_mode, :text

    Computer.reset_column_information
    Computer.find(:all).each do |c|
      c.temp_raw_mode = c.raw_mode
      c.save!
    end

    remove_column :computers, :raw_mode
    rename_column :computers, :temp_raw_mode, :raw_mode

    ### Bundles ###
    add_column :bundles, :temp_raw_mode, :text

    Bundle.reset_column_information
    Bundle.find(:all).each do |b|
      b.temp_raw_mode = b.raw_mode
      b.save!
    end

    remove_column :bundles, :raw_mode
    rename_column :bundles, :temp_raw_mode, :raw_mode

    ### Environments ###
    add_column :environments, :temp_environment_ids, :text

    Environment.find(:all).each do |e|
      e.temp_environment_ids = e.environment_ids
      e.save!
    end

    remove_column :environments, :environment_ids
    rename_column :environments, :temp_environment_ids, :environment_ids

    ### ComputerGroups ###
    add_column :computer_groups, :temp_raw_mode, :text

    ComputerGroup.reset_column_information
    ComputerGroup.find(:all).each do |c|
      c.temp_raw_mode = c.raw_mode
      c.save!
    end

    remove_column :computer_groups, :raw_mode
    rename_column :computer_groups, :temp_raw_mode, :raw_mode

  end

  def self.down
    ### Packages ###
    add_column :packages, :temp_receipts, :text, :default => "--- []"
    add_column :packages, :temp_supported_architectures, :text, :default => "--- []"
    add_column :packages, :temp_installs, :text, :default => "--- []"
    add_column :packages, :temp_raw_tags, :text, :default => "--- {}"

    Package.find(:all).each do |p|
      p.temp_receipts = p.receipts
      p.temp_supported_architectures = p.supported_architectures
      p.temp_installs = p.installs
      p.temp_raw_tags = p.raw_tags
      p.save!
    end

    remove_column :packages, :receipts
    rename_column :packages, :temp_receipts, :receipts
    remove_column :packages, :supported_architectures
    rename_column :packages, :temp_supported_architectures, :supported_architectures
    remove_column :packages, :installs
    rename_column :packages, :temp_installs, :installs
    remove_column :packages, :raw_tags
    rename_column :packages, :temp_raw_tags, :raw_tags

    ### Computers ###
    add_column :computers, :temp_raw_mode, :text, :default => false

    Computer.find(:all).each do |c|
      c.temp_raw_mode = c.raw_mode
      c.save!
    end

    remove_column :computers, :raw_mode
    rename_column :computers, :temp_raw_mode, :raw_mode

    ### Bundles ###
    add_column :bundles, :temp_raw_mode, :text, :default => false

    Bundle.find(:all).each do |b|
      b.temp_raw_mode = b.raw_mode
      b.save!
    end

    remove_column :bundles, :raw_mode
    rename_column :bundles, :temp_raw_mode, :raw_mode

    ### Environments ###
    add_column :environments, :temp_environment_ids, :text, :default => "--- []"

    Environment.find(:all).each do |e|
      e.temp_environment_ids = e.environment_ids
      e.save!
    end

    remove_column :environments, :environment_ids
    rename_column :environments, :temp_environment_ids, :environment_ids

    ### ComputerGroups ###
    add_column :computer_groups, :temp_raw_mode, :text, :default => false

    ComputerGroup.find(:all).each do |c|
      c.temp_raw_mode = c.raw_mode
      c.save!
    end

    remove_column :computer_groups, :raw_mode
    rename_column :computer_groups, :temp_raw_mode, :raw_mode

  end
end
