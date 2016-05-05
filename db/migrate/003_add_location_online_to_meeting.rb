class AddLocationOnlineToMeeting < ActiveRecord::Migration
  def change
    add_column :meetings, :location_online, :string, default: ''
  end
end
