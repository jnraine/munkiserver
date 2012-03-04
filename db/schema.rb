# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111208121600) do

  create_table "bundle_items", :force => true do |t|
    t.integer  "manifest_id"
    t.string   "manifest_type"
    t.integer  "bundle_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bundles", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "unit_id"
    t.integer  "environment_id"
    t.text     "raw_tags"
    t.text     "raw_mode",       :default => "f"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "shortname"
  end

  create_table "client_logs", :force => true do |t|
    t.integer  "computer_id"
    t.text     "managed_software_update_log"
    t.text     "errors_log"
    t.text     "installs_log"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "computer_groups", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "unit_id"
    t.integer  "environment_id"
    t.text     "raw_tags"
    t.text     "raw_mode",         :default => "f"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "configuration_id"
    t.string   "shortname"
  end

  create_table "computer_models", :force => true do |t|
    t.string   "name"
    t.string   "identifier"
    t.integer  "icon_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "computers", :force => true do |t|
    t.string   "mac_address"
    t.string   "name"
    t.text     "system_profiler_info"
    t.text     "description"
    t.integer  "computer_model_id"
    t.integer  "computer_group_id"
    t.integer  "unit_id"
    t.integer  "environment_id"
    t.text     "raw_tags"
    t.text     "raw_mode",             :default => "f"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "hostname",             :default => ""
    t.integer  "configuration_id"
    t.string   "shortname"
    t.datetime "last_report_at"
  end

  create_table "configurations", :force => true do |t|
    t.string   "configuration"
    t.boolean  "inherit",       :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "download_links", :force => true do |t|
    t.string   "text"
    t.string   "url"
    t.string   "caption"
    t.integer  "version_tracker_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "environments", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.text     "environment_ids", :default => "--- []"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "icons", :force => true do |t|
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "install_items", :force => true do |t|
    t.integer  "package_branch_id"
    t.integer  "package_id"
    t.integer  "manifest_id"
    t.string   "manifest_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "managed_install_reports", :force => true do |t|
    t.string   "ip"
    t.string   "manifest_name"
    t.string   "run_type"
    t.string   "console_user"
    t.string   "managed_install_version"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "available_disk_space"
    t.integer  "computer_id"
    t.text     "munki_errors"
    t.text     "munki_warnings"
    t.text     "install_results"
    t.text     "installed_items"
    t.text     "items_to_install"
    t.text     "items_to_remove"
    t.text     "machine_info"
    t.text     "managed_installs"
    t.text     "problem_installs"
    t.text     "removal_results"
    t.text     "removed_items"
    t.text     "managed_installs_list"
    t.text     "managed_uninstalls_list"
    t.text     "managed_updates_list"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "managed_update_items", :force => true do |t|
    t.integer  "package_branch_id"
    t.integer  "package_id"
    t.integer  "manifest_id"
    t.string   "manifest_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "memberships", :force => true do |t|
    t.integer  "unit_id"
    t.integer  "user_id"
    t.boolean  "create_computer",        :default => true
    t.boolean  "read_computer",          :default => true
    t.boolean  "edit_computer",          :default => true
    t.boolean  "destroy_computer",       :default => true
    t.boolean  "create_bundle",          :default => true
    t.boolean  "read_bundle",            :default => true
    t.boolean  "edit_bundle",            :default => true
    t.boolean  "destroy_bundle",         :default => true
    t.boolean  "create_computer_group",  :default => true
    t.boolean  "read_computer_group",    :default => true
    t.boolean  "edit_computer_group",    :default => true
    t.boolean  "destroy_computer_group", :default => true
    t.boolean  "create_package",         :default => true
    t.boolean  "read_package",           :default => true
    t.boolean  "edit_package",           :default => true
    t.boolean  "destroy_package",        :default => true
    t.boolean  "edit_unit",              :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "missing_manifests", :force => true do |t|
    t.string   "manifest_type"
    t.string   "identifier"
    t.string   "request_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "hostname"
  end

  create_table "notifications", :force => true do |t|
    t.integer  "notified_id"
    t.string   "notified_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "optional_install_items", :force => true do |t|
    t.integer  "package_branch_id"
    t.integer  "package_id"
    t.integer  "manifest_id"
    t.string   "manifest_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "package_branches", :force => true do |t|
    t.string   "name"
    t.string   "display_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "package_categories", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "icon_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "packages", :force => true do |t|
    t.string   "version"
    t.integer  "package_branch_id"
    t.integer  "unit_id"
    t.integer  "environment_id"
    t.integer  "package_category_id"
    t.text     "receipts",                  :default => "--- []"
    t.text     "description"
    t.integer  "icon_id"
    t.string   "filename"
    t.text     "supported_architectures",   :default => "--- []"
    t.text     "minimum_os_version"
    t.text     "maximum_os_version"
    t.text     "installs",                  :default => "--- []"
    t.string   "RestartAction"
    t.string   "package_path"
    t.boolean  "autoremove",                :default => false
    t.boolean  "shared",                    :default => false
    t.string   "version_tracker_version"
    t.string   "installer_type"
    t.integer  "installed_size"
    t.integer  "installer_item_size"
    t.string   "installer_item_location"
    t.text     "installer_choices_xml"
    t.boolean  "use_installer_choices",     :default => false
    t.string   "uninstall_method"
    t.string   "uninstaller_item_location"
    t.integer  "uninstaller_item_size"
    t.boolean  "uninstallable",             :default => true
    t.string   "installer_item_checksum"
    t.text     "raw_tags",                  :default => "--- {}"
    t.integer  "raw_mode_id",               :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "preinstall_script"
    t.text     "postinstall_script"
    t.text     "uninstall_script"
    t.text     "preuninstall_script"
    t.text     "postuninstall_script"
    t.boolean  "unattended_install",        :default => false
    t.boolean  "unattended_uninstall",      :default => false
    t.datetime "force_install_after_date"
  end

  create_table "permissions", :force => true do |t|
    t.integer  "principal_id"
    t.string   "principal_type"
    t.integer  "unit_id"
    t.integer  "privilege_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "privileges", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.boolean  "unit_specific", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "require_items", :force => true do |t|
    t.integer  "package_branch_id"
    t.integer  "package_id"
    t.integer  "manifest_id"
    t.string   "manifest_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sp_printers", :force => true do |t|
    t.string   "name"
    t.string   "cupsversion"
    t.string   "default"
    t.string   "driverversion"
    t.string   "fax"
    t.string   "ppd"
    t.string   "ppdfileversion"
    t.string   "printserver"
    t.string   "psversion"
    t.string   "scanner"
    t.string   "scanner_uuid"
    t.string   "scannerappbundlepath"
    t.string   "scannerapppath"
    t.string   "status"
    t.string   "uri"
    t.integer  "system_profile_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "system_profiles", :force => true do |t|
    t.integer  "computer_id"
    t.string   "cpu_type"
    t.string   "current_processor_speed"
    t.string   "l2_cache_core"
    t.string   "l3_cache"
    t.string   "machine_model"
    t.string   "machine_name"
    t.string   "number_processors"
    t.string   "physical_memory"
    t.string   "platform_uuid"
    t.string   "serial_number"
    t.string   "os_64bit_kernel_and_kexts"
    t.string   "boot_volume"
    t.string   "kernel_version"
    t.string   "local_host_name"
    t.string   "os_version"
    t.string   "uptime"
    t.string   "user_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "uninstall_items", :force => true do |t|
    t.integer  "package_branch_id"
    t.integer  "package_id"
    t.integer  "manifest_id"
    t.string   "manifest_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "unit_settings", :force => true do |t|
    t.boolean  "notify_users"
    t.string   "unit_email"
    t.text     "regular_events"
    t.text     "warning_events"
    t.text     "error_events"
    t.integer  "unit_id"
    t.boolean  "version_tracking"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "units", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "key"
    t.integer  "unit_member_id"
    t.integer  "unit_member_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "configuration_id"
    t.string   "shortname"
  end

  create_table "update_for_items", :force => true do |t|
    t.integer  "package_branch_id"
    t.integer  "package_id"
    t.integer  "manifest_id"
    t.string   "manifest_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_allowed_items", :force => true do |t|
    t.integer  "package_branch_id"
    t.integer  "package_id"
    t.integer  "manifest_id"
    t.string   "manifest_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_group_memberships", :force => true do |t|
    t.integer  "principal_id",   :null => false
    t.string   "principal_type", :null => false
    t.integer  "user_group_id",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_groups", :force => true do |t|
    t.string   "name"
    t.string   "shortname"
    t.text     "description"
    t.integer  "unit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_install_items", :force => true do |t|
    t.integer  "package_branch_id"
    t.integer  "package_id"
    t.integer  "manifest_id"
    t.string   "manifest_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_settings", :force => true do |t|
    t.boolean  "receive_email_notifications"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_uninstall_items", :force => true do |t|
    t.integer  "package_branch_id"
    t.integer  "package_id"
    t.integer  "manifest_id"
    t.string   "manifest_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "hashed_password"
    t.string   "email"
    t.string   "salt"
    t.boolean  "super_user",      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "version_trackers", :force => true do |t|
    t.integer  "package_branch_id"
    t.integer  "web_id"
    t.string   "version"
    t.string   "download_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "icon_id"
    t.text     "description"
  end

  create_table "warranties", :force => true do |t|
    t.string   "serial_number",           :default => ""
    t.string   "product_description",     :default => ""
    t.string   "product_type",            :default => ""
    t.datetime "purchase_date"
    t.datetime "hw_coverage_end_date"
    t.datetime "phone_coverage_end_date"
    t.boolean  "registered"
    t.boolean  "hw_coverage_expired"
    t.boolean  "phone_coverage_expired"
    t.boolean  "app_registered"
    t.boolean  "app_eligible"
    t.string   "specs_url",               :default => ""
    t.string   "hw_support_url",          :default => ""
    t.string   "forum_url",               :default => ""
    t.string   "phone_support_url",       :default => ""
    t.integer  "computer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
