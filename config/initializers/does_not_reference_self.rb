class DoesNotReferenceSelfValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    if record.principal_id == value
      record.errors.add attribute, 'must not reference itself as a member'
    end
  end
end