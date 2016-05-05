class CreateMeetings < ActiveRecord::Migration
  def change
    create_table :meetings do |t|

      t.string :subject
      t.string :status
      t.integer :project_id
      t.integer :user_id

      t.boolean :location

      t.date :date

      t.string :time

      t.text :agenda
      t.text :meeting_minutes
      t.timestamps


    end

  end
end
