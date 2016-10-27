class MeetingsController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id
  before_filter :authorize, except: [:calendar, :participate, :not_participating, :schedule]
  before_filter :get_meeting, only: [:edit, :update, :destroy, :show, :participate, :not_participating]

  before_filter :set_calendar, only: [:calendar, :schedule]

  helper :custom_fields
  include CustomFieldsHelper
  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  helper :issues
  include IssuesHelper
  helper :calendars
  include CalendarsHelper

  def index
    @query = MeetingQuery.build_from_params(params, :name => '_')

    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid?
      case params[:format]
        when 'csv', 'pdf'
          @limit = Setting.issues_export_limit.to_i
          if params[:columns] == 'all'
            @query.column_names = @query.available_inline_columns.map(&:name)
          end
        when 'atom'
          @limit = Setting.feeds_limit.to_i
        when 'xml', 'json'
          @offset, @limit = api_offset_and_limit
          @query.column_names = %w(author)
        else
          @limit = per_page_option
      end
      sort_clause ||= 'date DESC, start_time ASC'
      scope = @query.results_scope(:order => sort_clause, project_id: @project.id )
      @entry_count = scope.count
      @entry_pages = Paginator.new @entry_count, per_page_option, params['page']
      @meetings = scope.offset(@entry_pages.offset).limit(@entry_pages.per_page).all
      render :layout => !request.xhr?
    else
      respond_to do |format|
        format.html { render(:template => 'issues/index', :layout => !request.xhr?) }
        format.any(:atom, :csv, :pdf) { render(:nothing => true) }
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end


  def new
    @meeting = Meeting.new(project_id: @project.id, status: 'New')
  end

  def create
    @meeting = Meeting.new(project_id: @project.id,
                           status: 'New',
                           user_id: User.current.id)

    if  Redmine::VERSION::MAJOR > 3
    @meeting.safe_attributes= params[:meeting].merge(params[:schedule]).permit!

      else
       @meeting.safe_attributes= params[:meeting].merge(params[:schedule])
    end
    if @meeting.save
      users = User.where(id: params[:users])
      @meeting.users<< users
      # TODO Send notification for all members
      Mailer.deliver_send_meeting(@meeting, users)

      flash[:notice] = "Meeting created successfully"
      redirect_back_or_default project_meetings_path(@project)
    else
      render :new
    end
  end

  def participate
    meeting_user = @meeting.meeting_users.where(user_id: User.current.id).first
    if !meeting_user
      flash[:error] = 'You are not belong to this meeting'
      redirect_to calendar_project_meetings_path(@meeting.project)
    end
  end

  def not_participating
    meeting_user = @meeting.meeting_users.where(user_id: User.current.id).first
    meeting_user.delete if meeting_user
    redirect_to calendar_project_meetings_path(@meeting.project, @meeting)
  end

  def show

  end


  def edit
  end

  def update
    if  Redmine::VERSION::MAJOR > 3
      @meeting.safe_attributes= params[:meeting].merge(params[:schedule]).permit!
    else
      @meeting.safe_attributes= params[:meeting].merge(params[:schedule])
    end 

    if @meeting.save
      new_users = params[:users].map(&:to_i) - @meeting.users.map(&:id)
      users = User.where(id: params[:users])
      @meeting.users= users
      if new_users.present?
        Mailer.deliver_send_meeting(@meeting, User.where(id: new_users))
      end
      flash[:notice] = "Meeting updated successfully"
      redirect_back_or_default project_meetings_path(@project)
    else
      render :edit
    end
  end

  def destroy
    @meeting.destroy
    redirect_back_or_default project_meetings_path(@project)
  end

  def calendar

  end

  def schedule
    @day = params[:day].to_i
    day = "#{@day}/#{@month}/#{@year}".to_date
    @schedules_array = []
    @events_array= []
    @events.select{|meeting|
      meeting.can_show?(day)
    }.sort_by{|a| a.start_time}.each do |meeting|
      if meeting.end_time.presence
        @events_array<<{
            date: "#{day.strftime('%Y/%m/%d')} #{meeting.start_time}",
            title: "#{meeting.subject}--#{meeting.location_online}"
        }
      else
        @events_array<<{
            date: "#{day.strftime('%Y/%m/%d')} #{meeting.start_time}",
            title: "#{meeting.subject} --#{meeting.location_online}"
        }
      end
    end
  end

  private

  def set_calendar
    if params[:year] and params[:year].to_i > 1900
      @year = params[:year].to_i
      if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
        @month = params[:month].to_i
      end
    end
    @year ||= Date.today.year
    @month ||= Date.today.month

    @calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)
    retrieve_query
    @query.group_by = nil
    @events = []
    if @query.valid?
      @events = []
      @q2 = MeetingQuery.build_from_params(params, :name => '_')
      scope = Meeting.visible.where(project_id: @project.id)
      unless params[:show_all]
        scope = scope.where(status:'New')
      end
      @events = scope.where("(date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?)", @calendar.startdt, @calendar.enddt,@calendar.startdt, @calendar.enddt)

      @calendar.events = @events
    end
  end

  def get_meeting
    @meeting = Meeting.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
