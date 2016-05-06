namespace :redmine_meeting_reminder do
  task :reminder => :environment do
    Meeting.find_coming_meeting(40)
  end

  task :complete_meetings => :environment do
    Meeting.turn_to_completed
  end
end
