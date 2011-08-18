class DateTimeValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    unless value.match(/\A^(""|\d{4}-\d{2}-\d{2} \d{2}:\d{2} (AM|PM))$\z/).instance_of?(MatchData)
      record.errors.add_to_base  'Force Install After Date is not in the form of YYYY-MM-DD HH:MM AM/PM'
    end
  end
end