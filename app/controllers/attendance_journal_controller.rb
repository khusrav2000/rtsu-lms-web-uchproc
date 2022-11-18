class AttendanceJournalController < ApplicationController
  before_action :require_user
  
  def index 
    js_bundle :attendance_journal
    css_bundle :attendance_journal
  end

  # def index
  #   if @current_user.can_access_any_account_journals?([:attendance_journal_view, :attendance_journal_edit]) ||
  #     @current_user.can_access_any_course_journals?([:attendance_journal_view, :attendance_journal_edit])
  #     js_bundle :attendance_journal
  #     css_bundle :attendance_journal
  #   else
  #     render "shared/unauthorized", status: :unauthorized, content_type: Mime::Type.lookup('text/html'), formats: :html
  #   end
  # end

  def attendance
    get_context
    return unless authorized_action(@context, @current_user, [:attendance_journal_view, :attendance_journal_edit])
    js_env({
             :COURSE_ID => params[:course_id]
           })
    js_bundle :attendance
    css_bundle :attendance
  end
end

