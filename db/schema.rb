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

ActiveRecord::Schema.define(:version => 20110218132953) do

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
    t.text     "raw_mode",       :default => "f"
    t.datetime "created_at"
    t.datetime "updated_at"
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
  end

  create_table "require_items", :force => true do |t|
    t.integer  "package_branch_id"
    t.integer  "package_id"
    t.integer  "manifest_id"
    t.string   "manifest_type"
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
  end

end
