class MigrateToNewSchedule< ActiveRecord::Migration
  def up
    Meeting.all.each do |meeting|
      meeting.recurring_type = "1" if meeting.recurring_time == "1"
      meeting.recurring_type = "2" if meeting.recurring_time == "3"
      meeting.recurring_type = "3" if meeting.recurring_time == "2"
      if meeting.recurring_time == "2" # weekly
        meeting.weekly_recurring = '1'
        begin
        meeting.days_recurring = eval(meeting.recurring_week_days)
        rescue
        end
      end

      meeting.save

    end
  end
end