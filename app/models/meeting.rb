class Meeting < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes

  belongs_to :user
  belongs_to :project

  has_many :meeting_users
  has_many :users, through: :meeting_users


  validates_presence_of :subject, :date, :start_time, :status, :project_id, :user_id
  # validates_presence_of :meeting_minutes, :if => :check_status

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
                  'meeting_minutes'

  scope :visible, lambda {|*args|
    if User.current.admin?
      includes(:project)
    else
      includes(:project, :meeting_users).references(:project, :meeting_users).where("meeting_users.user_id= ? OR #{table_name}.user_id = ?", User.current.id, User.current.id)
    end
  }

  def due_date
    date
  end

  def start_date
    date
  end

  # def check_status
  #   return false if status.camelcase == 'New'
  #   true
  # end

  def editable_by?(usr= User.current)
    usr == user && usr.allowed_to?(:edit_meeting, project)
  end

  # Returns true if the attribute is required for user
  def required_attribute?(name, user=nil)
    required_attribute_names(user).include?(name.to_s)
  end

  def can_show?(day)
    if self.recurring_type == '1' # one time
      return day == self.date
    elsif self.recurring_type == '2' # daily
      return self.date <= day &&  day <= self.end_date
    elsif self.recurring_type == '3' #weekly
      w_recurring = self.weekly_recurring.to_i
      cweek = day.cweek
      if ((cweek-self.date.cweek)%w_recurring).zero? &&  self.date <= day &&  day <= self.end_date
        return true if self.days_recurring.include?("#{day.cwday}")
      end
    elsif  self.recurring_type == '4'
      return false if self.monthly_recurring.nil?
      dates = self.monthly_recurring.first.split(',').map(&:strip)
      return true if  dates.include?(day.strftime('%-m/%-d/%Y')) or dates.include?(day.strftime('%-m/%-d/%y'))
    else
      false
    end
    false
  rescue
    false
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
