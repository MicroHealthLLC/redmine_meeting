class AddColumnToMeeting < ActiveRecord::Migration
  def change
    add_column :meetings, :recurring_time, :string, default: ''
    add_column :meetings, :end_time, :string, default: ''
    rename_column :meetings, :time, :start_time
  end
end
