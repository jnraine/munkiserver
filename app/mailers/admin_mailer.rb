class AdminMailer < ActionMailer::Base
  default :from => "Munki Server <notifications@example.com>"
  
  include ActionView::Helpers
  
  # Error report including all logs and the last successful run time
  def computer_error(computer)
    @computer = computer
    admins = @computer.admins.delete_if {|e| e.settings.receive_email_notifications == false }
    mail(:to => admins.map(&:email), :subject => "Computer error: #{@computer}")
  end
  
  # A list of computers that are considered "dormant", including their
  # last successful run, and their last run (if different than last
  # successful run).  List should contain units from only one unit!
  def dormant_computers(unit)
    @unit = unit
    @computers = Computer.dormant(unit)
    admins = @unit.members.delete_if {|e| e.settings.receive_email_notifications == false }
    mail(:to => admins.map(&:email), :subject => "#{pluralize(@computers.count, "dormant computer")} in #{@unit} unit")
  end
end
