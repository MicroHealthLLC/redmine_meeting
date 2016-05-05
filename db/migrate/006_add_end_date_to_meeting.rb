class AddEndDateToMeeting < ActiveRecord::Migration
  def change
    add_column :meetings, :end_date, :date
  end
end
