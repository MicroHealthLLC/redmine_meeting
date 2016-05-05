class MeetingUser < ActiveRecord::Base
  unloadable

  belongs_to :user
  belongs_to :meeting
end
