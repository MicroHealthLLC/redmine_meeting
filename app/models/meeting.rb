class Meeting < ActiveRecord::Base
  unloadable

  class MeetingRecurringType
    ONE_TIME = 1
    DAILY    = 2
    WEEKLY   = 3
    CUSTOM   = 4
  end


  include Redmine::SafeAttributes

  belongs_to :user
  belongs_to :project

  has_many :meeting_users
  has_many :users, through: :meeting_users


  validates_presence_of :subject, :date, :start_time, :status, :project_id, :user_id
  # validates_presence_of :meeting_minutes, :if => :check_status
  validates_presence_of :days_recurring, :if => :check_days_recurring

  store :schedule,
        accessors: %w(recurring_type weekly_recurring monthly_recurring days_recurring)


  safe_attributes 'subject',
                  'location',
                  'location_online',
                  'project_id',
                  'user_id',
                  'recurring_type',
                  'days_recurring',
                  'weekly_recurring',
                  'monthly_recurring',
                  'end_time',
                  'start_time',
                  'status',
                  'date',
                  'end_date',
                  'agenda',
                  'custom_field_values',
                  'meeting_minutes',
                  'archive'

  scope :visible, lambda {|*args|
    if User.current.admin?
      includes(:project)
    else
      includes(:project, :meeting_users).references(:project, :meeting_users).where("meeting_users.user_id= ? OR #{table_name}.user_id = ?", User.current.id, User.current.id)
    end
  }
  def self.not_archived
    where(archive: false)
  end

  def due_date
    date
  end

  def start_date
    date
  end

  def check_days_recurring
    if self.recurring_type.to_i == MeetingRecurringType::WEEKLY
      if self.days_recurring.map(&:presence).compact.blank?
        errors.add(:base, 'For weekly recurring, you have to choose at least one day.')
      end
    elsif self.recurring_type.to_i == MeetingRecurringType::CUSTOM
      if self.monthly_recurring.join('').strip.blank?
        errors.add(:base, 'For monthly recurring, you have to choose at least one day.')
      end
    end
  end

  def editable_by?(usr= User.current)
    User.current.admin? or usr == user && usr.allowed_to?(:edit_meeting, project)
  end

  # Returns true if the attribute is required for user
  def required_attribute?(name, user=nil)
    required_attribute_names(user).include?(name.to_s)
  end

  def can_show?(day)
    return false if self.date.nil?

    case self.recurring_type.to_i
      when MeetingRecurringType::ONE_TIME then
        return day == self.date
      when MeetingRecurringType::DAILY then
        if self.end_date.nil?
          return self.date <= day
        end
        return self.date <= day &&  day <= self.end_date
      when MeetingRecurringType::WEEKLY then
        w_recurring = self.weekly_recurring.to_i
        return false if self.days_recurring.nil?
        cweek = day.cweek

        if self.end_date.nil?
          if ((cweek-self.date.cweek)%w_recurring).zero? &&  self.date <= day
            return true if self.days_recurring.include?("#{day.cwday}")
          end
        else
          if ((cweek-self.date.cweek)%w_recurring).zero? &&  self.date <= day &&  day <= self.end_date
            return true if self.days_recurring.include?("#{day.cwday}")
          end
        end
      when MeetingRecurringType::CUSTOM then
        return false if self.monthly_recurring.nil?
        dates = self.monthly_recurring.first.split(',').map(&:strip)
        return true if  dates.include?(day.strftime('%-m/%-d/%Y')) or dates.include?(day.strftime('%-m/%-d/%y'))
      else
        false
    end
  end

  def self.find_coming_meeting(hours=6)
    now = Time.now
    time = now + hours.hours

    Meeting.where(status: 'New').where('date BETWEEN ? AND ? ', now.to_date, time.to_date).each do |meeting|
      mn = meeting.start_time
      dt = meeting.start_date
      if dt.present?
        d_time = dt.to_date.strftime("%d/%B/%Y #{mn}").to_time
        if now < d_time &&  d_time < time
          meeting.users.each do |user|
            Mailer.deliver_remember_meeting(user, meeting)
          end
        end
      end
    end
  end

  def self.turn_to_completed
    Meeting.where("end_date IS NOT NULL AND end_date < ? AND status= 'New'", Date.today).update_all(status: 'Completed')
  end



end
