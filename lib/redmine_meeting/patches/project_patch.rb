require_dependency 'project'

module  RedmineMeeting
  module  Patches
    module ProjectPatch
      def self.included(base)
        base.class_eval do
          has_many :meetings
        end
      end
    end
  end
end
