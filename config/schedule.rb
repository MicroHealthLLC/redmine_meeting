every :day, at: '7:00' do
  rake 'redmine_meeting_reminder:reminder'
end

every :day, at: '0:05' do
  rake 'redmine_meeting_reminder:complete_meetings'
end
