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
    mail(:bcc => recipients_for_unit(unit), :subject => "[Munki Server] #{@packages.count} packages have update in #{unit.name}! ")
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
  def recipients(record)
    if record.present?
      members = record.unit.members if record.unit.present?
      members.delete_if {|e| e.settings.receive_email_notifications == false }.map(&:email)
    else
      []
    end
  end
  
  def recipients_for_unit(unit)
    if unit.present?
      members = unit.members
      members.delete_if {|e| e.settings.receive_email_notifications == false }.map(&:email)
    else
      []
    end
  end
end
