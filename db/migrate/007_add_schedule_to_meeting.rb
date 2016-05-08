class AddScheduleToMeeting < ActiveRecord::Migration
  def change
    add_column :meetings, :schedule, :text
  end
end
