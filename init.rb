Redmine::Plugin.register :redmine_meeting do
  name 'Redmine Meeting plugin'
  author 'Bilel Kedidi'
  description 'This is a plugin for Redmine'
  version '1.1.0'

  project_module :redmine_meeting do
    permission :view_meeting_calendar, :meetings => [:calendar]
    permission :view_meetings, :meetings => [:index, :show]
    permission :create_meeting, :meetings => [:new, :create]
    permission :edit_meeting, :meetings => [:edit, :update , :destroy]
  end

  menu :project_menu, :meetings,
       {:controller => 'meetings', :action => 'calendar'},
       :caption => :label_meeting_plural,
       :before => :activity, param: :project_id
end


Rails.application.config.to_prepare do
  Project.send(:include, RedmineMeeting::Patches::ProjectPatch)
  User.send(:include, RedmineMeeting::Patches::UserPatch)
  QueriesHelper.send(:include, RedmineMeeting::Patches::QueriesHelperPatch)
  Mailer.send(:include, RedmineMeeting::Patches::MailerPatch)
end

