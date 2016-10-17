module MeetingsHelper

  def calendar_for_meeeting(field_id)
    include_calendar_headers_tags_for_meeting
    javascript_tag("$(function() { $('##{field_id}').addClass('date').datepicker(datepickerOptions); });")
  end

  def include_calendar_headers_tags_for_meeting
    unless @calendar_headers_tags_included
      tags = ''.html_safe
      @calendar_headers_tags_included = true
      content_for :header_tags do
        start_of_week = Setting.start_of_week
        start_of_week = l(:general_first_day_of_week, :default => '1') if start_of_week.blank?
        # Redmine uses 1..7 (monday..sunday) in settings and locales
        # JQuery uses 0..6 (sunday..saturday), 7 needs to be changed to 0
        start_of_week = start_of_week.to_i % 7
        tags <<  javascript_tag(
            "var datepickerOptions={dateFormat: 'yy-mm-dd', firstDay: #{start_of_week}};")
        jquery_locale = l('jquery.locale', :default => current_language.to_s)
        unless jquery_locale == 'en'
          tags << javascript_include_tag("i18n/datepicker-#{jquery_locale}.js")
        end
        tags
      end
    end
  end
end
