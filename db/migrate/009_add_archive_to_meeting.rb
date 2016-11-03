class AddArchiveToMeeting< ActiveRecord::Migration
  def change
    add_column :meetings, :archive, :boolean, default: false
  end
end