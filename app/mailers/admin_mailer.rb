class AdminMailer < ActionMailer::Base
  default :from => "Munki Server <no_reply@example.com>"

  helper :application
  
  # Send a current report for a given computer
  def computer_report(computer)
    @computer = computer
    mail(:bcc => recipients(@computer), :subject => "[Munki Server] #{@computer}: #{@computer.status}")
  end
  
  def package_update_available(package)
    @package = package
    mail(:bcc => recipients(@package), :subject => "[Munki Server] #{@package.to_s(:pretty)} has an update! ")
  end
  
  def available_updates_digest(unit)
    @packages = PackageBranch.available_updates(unit)
    mail(:bcc => recipients_for_unit(unit,:package), :subject => "[Munki Server] #{@packages.count} packages have update in #{unit.name}! ")
  end
  
  def warranty_notification(computer)
    @computer = computer
    mail(:bcc => recipients(@computer), :subject => "[Munki Server] #{@computer}'s warranty will expire in #{@computer.warranty.days_left} days")
  end
  
  # # A list of computers that are considered "dormant", including their
  # # last successful run, and their last run (if different than last
  # # successful run).  List should contain units from only one unit!
  # def dormant_computers(unit)
  #   @unit = unit
  #   @computers = Computer.dormant(unit)
  #   admins = @unit.members.delete_if {|e| e.settings.receive_email_notifications == false }
  #   mail(:to => admins.map(&:email), :subject => "#{pluralize(@computers.count, "dormant computer")} in #{@unit} unit")
  # end
  
  private
  # Obain the email addresses as an array for a given model.  This uses the model
  # name and the model unit to determine the list of users.  Users who can read
  # the model type in the specific unit are returned.
  def recipients(record)
    if record.present?
      recipients_for_unit(record.unit,record.class.to_s)
    else
      []
    end
  end
  
  def recipients_for_unit(unit,model_name)
    if unit.present?
      users = unit.users_who_can_read(model_name.to_s.tableize)
      users.delete_if {|e| e.settings.present? and e.settings.receive_email_notifications == false }.map(&:email)
    else
      []
    end
  end
end
