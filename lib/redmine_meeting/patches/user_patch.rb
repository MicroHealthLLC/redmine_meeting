require_dependency 'user'

module  RedmineMeeting
  module  Patches
    module UserPatch
      def self.included(base)
        base.class_eval do
          has_many :meetings
          has_many :meeting_users
        end
      end
    end
  end
end
