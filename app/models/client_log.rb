class ClientLog < ActiveRecord::Base
  belongs_to :computer
  
  # Glean the runtype from the log details
  # If not present, returns nil
  def run_type
    begin
      details.match(/(runtype: )(.+)(\.\.\.$)/)[2]
    rescue
    end
  end
end
