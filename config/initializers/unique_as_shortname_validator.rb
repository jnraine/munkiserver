# Conforms a given attribute to a shortname using record#conform_name_to_shortname,
# then checks to ensure there is only one record with that shortname in a given scope.
# Works only with instances of Unit, Computer, ComputerGroup, and Bundle.
class UniqueAsShortnameValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    shortname = record.conform_name_to_shortname(value) if value.present?
    matching_records = nil
    if record.is_a? Unit
      # Record is an instance of Unit
      matching_records = Unit.where(:shortname => shortname)
    elsif [Computer, ComputerGroup, UserGroup, Bundle].include?(record.class)
      # Record is an instance of Computer, ComputerGroup, UserGroup, or Bundle
      matching_records = record.class.where(:shortname => shortname, :unit_id => record.unit_id)
    else
      raise Exception.new("#{self.class} must only be used for Unit, Computer, ComputerGroup, UserGroup, or Bundle records")
    end
    
    single_result_is_not_this_record = (matching_records.count == 1 and matching_records.first.id != record.id)
    if single_result_is_not_this_record or matching_records.count > 1
      record.errors.add_to_base "Shortname generated from #{attribute} of this record is already taken, please give another name"
    end
  end
end