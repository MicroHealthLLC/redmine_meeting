require_dependency 'queries_helper'

module  RedmineMeeting
  module  Patches
    module QueriesHelperPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :column_value, :meeting
        end
      end

    end
    module ClassMethods

    end

    module InstanceMethods
      def column_value_with_meeting(column, issue, value)
        if issue.is_a?(Meeting) and column.name == :subject
          link_to value, project_meeting_path(issue.project, issue)
        else
          column_value_without_meeting(column, issue, value)
        end
      end
    end
  end
end