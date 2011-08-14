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
    # Remove any "zero" value (includes non-integer values)
    user_ids = @unit_params[:user_ids].collect {|id| id.to_i }.delete_if {|id| id == 0 }
    
    # Add user IDs
    @unit.user_ids = user_ids
    
    # Remove user IDs from @unit_params
    @unit_params.delete(:user_ids)
  end
end