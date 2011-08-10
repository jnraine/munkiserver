class UnitService
  attr_accessor :unit, :unit_params

  def initialize(params)
    @unit = Unit.find_by_shortname(params[:id])
    @unit_params = params[:unit]
  end
  
  # Returns the name of the unit in this service
  def name
    @unit.name
  end

  # Adds users manually and then calls save on @unit
  def save
    add_users
    @unit.update_attributes(@unit_params)
  end
  
  # Takes an array of user IDs and immediately creates a relationship
  # between the user and the unit
  def add_users
    # Find the corresponding keys
    user_keys = @unit_params.keys.collect{|key| key if key =~ /^role_sym_of_\S+$/}.compact!
    
    # Get usernames
    usernames = user_keys.collect{|key| key.to_s.sub(/^role_sym_of_/, '')}
    users = User.where(username: usernames)

    # Clear out past assignments
    @unit.assignments.destroy_all
    
    # Assign each to the unit
    users.each_with_index do |user, i|
      role = Role.find_by_sym(@unit_params[user_keys[i]])
      if role.present?
        puts "Adding #{user} to #{@unit.name} as #{role.name}"
        Assignment.create(user_id: user.id, role_id: role.id, unit_id: @unit.id)
      end
    end
    
    # Remove user IDs from @unit_params
    user_keys.each do |key|
      @unit_params.delete(key)
    end
  end
end