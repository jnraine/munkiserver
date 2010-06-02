# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key    => '_munki_session',
  :secret => '4c420f7546bc3e8d0732775928b9f5f5c075a5750a0b8611807cfa7c334b57b83d98019e21279ab5343c1c4a76df6dd86f72ebefaa9390453cbd0fb62c914948'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
