class RemoveDefaultValuesFromTextColumns < ActiveRecord::Migration
  def self.up
    ### Packages ###
    package_columns = ["receipts", "supported_architectures", "installs", "raw_tags"]

    package_columns.each do |column|
      unless Package.columns_hash["#{column}"].default.nil?
        add_column :packages, :"temp_#{column}", :text

        Package.reset_column_information
        Package.find(:all).each do |p|
          content = Package.find(p.id)
          p.send("temp_#{column}=", content[column])
          p.save!
        end

        remove_column :packages, :"#{column}"
        rename_column :packages, :"temp_#{column}", :"#{column}"

      end
    end

    ### Environments ###
    unless Environment.columns_hash["environment_ids"].default.nil?
      add_column :environments, :temp_environment_ids, :text

      Environment.reset_column_information
      Environment.find(:all).each do |e|
        e.temp_environment_ids = e.environment_ids
        e.save!
      end

      remove_column :environments, :environment_ids
      rename_column :environments, :temp_environment_ids, :environment_ids
    end


    ### Computers, Bundles and Computer Groups ###
    table_classes = ["computers", "bundles", "computer_groups"]

    table_classes.each do |table|
      klass = ActiveRecord::Base.const_get(table.classify)

      unless klass.columns_hash["raw_mode"].default.nil?
        add_column :"#{table}", :temp_raw_mode, :text

        klass.reset_column_information
        klass.find(:all).each do |c|
          c.temp_raw_mode = c.raw_mode
          c.save!
        end

        remove_column :"#{table}", :raw_mode
        rename_column :"#{table}", :temp_raw_mode, :raw_mode
      end
    end

  end

  def self.down
    adapter = ActiveRecord::Base.connection.instance_values["config"][:adapter]

    unless adapter == "mysql2"
      ### Packages ###
      package_columns = ["receipts", "supported_architectures", "installs"]

      package_columns.each do |column|
        change_column :packages, :"#{column}", :text, :default => "--- []"
      end

      change_column :packages, :raw_tags, :text, :default => "--- {}"
  
      ### Environments ###
      change_column :environments, :environment_ids, :text, :default => "--- []"

      ### Computers, Bundles and Computer Groups ###
      table_classes = ["computers", "bundles", "computer_groups"]

      table_classes.each do |table|
        klass = ActiveRecord::Base.const_get(table.classify)

        change_column :"#{table}", :raw_mode, :text, :default => false
      end
    end
  end
end
