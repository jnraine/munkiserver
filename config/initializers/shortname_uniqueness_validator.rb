# To be used only with package version attribute until package branch is unique
# to a unit as well.
class ShortnameUniquenessValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    shortname = value.downcase.lstrip.rstrip.gsub(/[^a-z0-9]+/, '-') if value.present?
    # if the record is Unit
    if record.class == Unit
      # if there exists the shortname
      if Unit.where(:shortname => shortname).count > 0
        # attribute = :shortname
        record.errors.add_to_base 'Shortname generated from name of this unit is already taken, please give another name'
      end

    # everything else that are unit dependent need to have uniqunesss within the unit  
    else
      if record.class.where(:shortname => shortname, :unit_id => record.unit_id).count > 0
        # attribute = :shortname
        record.errors.add_to_base 'Shortname generated from name of this record is already taken, please give another name'
      end
    end
  end
end