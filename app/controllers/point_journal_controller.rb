class PointJournalController < ApplicationController
  before_action :require_user
  def index
    if @current_user.can_access_any_account_journals?([:point_journal_view, :point_journal_edit]) ||
      @current_user.can_access_any_course_journals?([:point_journal_view, :point_journal_edit])
      js_bundle :point_journal
      css_bundle :point_journal
    else
      render "shared/unauthorized", status: :unauthorized, content_type: Mime::Type.lookup('text/html'), formats: :html
    end

  end

  def points
    get_context
    return unless authorized_action(@context, @current_user, [:point_journal_view, :point_journal_edit])
    js_env({
             :COURSE_ID => params[:course_id]
           })
    js_bundle :points
    css_bundle :point_journal
  end
end

