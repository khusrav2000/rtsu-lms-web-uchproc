class JournalsController < ApplicationController
  before_action :require_user
  before_action :get_context
  include Api::V1::Json
  include CustomSidebarLinksHelper
  include SupportHelpers::ControllerHelpers

  ITEM_POINT_JOURNAL = 'POINT_JOURNAL'
  ITEM_ATTENDANCE_JOURNAL = 'ATTENDANCE_JOURNAL'
  ITEM_STUDENT_POINT = 'STUDENT_POINT'
  ITEM_STUDENT_ATTENDANCE = 'STUDENT_ATTENDANCE'

  BASE_ITEMS = [
    {
      id: ITEM_POINT_JOURNAL,
      name: 'Point journal',
      html_url: "/journals/point_journal"
    }.freeze,
    {
      id: ITEM_ATTENDANCE_JOURNAL,
      name: 'Attendance journal',
      html_url: "/journals/attendance_journal"
    }.freeze,
    {
      id: ITEM_STUDENT_POINT,
      name: 'Student point',
      html_url: "/journals/my_point_journal"
    }.freeze,
    {
      id: ITEM_STUDENT_ATTENDANCE,
      name: 'Student attendance',
      html_url: "/journals/my_attendance_journal"
    }.freeze
  ].freeze

  def index
    respond_to do |format|
      items = []
      #if @current_user.can_access_any_account_journals?([:point_journal_view, :point_journal_edit]) ||
      #   @current_user.can_access_any_course_journals?([:point_journal_view, :point_journal_edit])
      #  items <<  BASE_ITEMS[0]
      #end
      items << BASE_ITEMS[0]
      #if @current_user.can_access_any_account_journals?([:attendance_journal_view, :attendance_journal_edit]) ||
      #  @current_user.can_access_any_course_journals?([:attendance_journal_view, :attendance_journal_edit])
      #  items << BASE_ITEMS[1]
      #end
      items << BASE_ITEMS[1]
      #if @current_user.can_access_any_account_journals?([:student_points]) || @current_user.can_access_any_course_journals?([:student_points])
      #  items << BASE_ITEMS[2]
      #end
      #if @current_user.can_access_any_account_journals?([:student_attendance]) || @current_user.can_access_any_course_journals?([:student_attendance])
      #  items << BASE_ITEMS[3]
      #end
      format.html do
        @journals = items
      end
      format.json do
        render :json => items
      end
    end
  end
end

