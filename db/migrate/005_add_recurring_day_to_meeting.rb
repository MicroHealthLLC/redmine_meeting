class AddRecurringDayToMeeting < ActiveRecord::Migration
  def change
    add_column :meetings, :recurring_week_days, :string, default: ''
  end
end
