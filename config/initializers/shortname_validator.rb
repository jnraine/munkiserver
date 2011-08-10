class ShortnameValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    result = value.match(/^[a-z0-9-]+$/)
    unless result.instance_of?(MatchData)
      record.errors.add attribute, 'a shortname of this object has already taken, please try to give another name'
    end
  end
end