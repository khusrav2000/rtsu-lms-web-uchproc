class PointJournalApiController < ApplicationController
  before_action :require_user
  include Api::V1::PointJournal
  include Uchproc::Apis::RequestHelper

  def points
    token = @current_user.pseudonyms.first.uchproc_token
    course_id = params[:uchproc_course_id]
    points = get_points(token, course_id)
    puts points
    puts points[:error]
  
    if points[:error]
      if points[:logout]
        logout_current_user
        flash[:logged_out] = true
        redirect_to login_url
        return
      end
      render :json => {:error => points[:error]}, :status => points[:status]
      return
    end
    payload = points[:payload]
    header = {}
    header[:rating] = {
      first: [],
      second: []
    }
    header[:max_week_point] = payload["max_point"]
    len = payload["header"].length() / 2
    payload["header"].each do |week|
      if week["number"].to_i <= len
        header[:rating][:first] << {
          number: week["number"],
          is_editable: week["editable"]
        }
      else
        header[:rating][:second] << {
          number: week["number"],
          is_editable: week["editable"]
        }
      end
    end
    payload["header"] = header
    render :json => payload
  end

  def update_week_points
    token = @current_user.pseudonyms.first.uchproc_token
    course_id = params[:course_id]
    new_points = []
    if params[:students_points]
      params[:students_points].each do |point|
        new_points << {
          id: point[:studentId].to_i,
          point: point[:weekPoint][:point]
        }
      end
    end

    points = update_points(token, course_id, new_points)

    if points[:error]
      if points[:logout]
        logout_current_user
        flash[:logged_out] = true
        redirect_to login_url
        return
      end
      render :json => {:error => points[:error]}, :status => points[:status]
      return
    end

    render :json => {:success => "yes"}
    
  end

  # OLD version
  # def points
  #   get_context
  #   course_ext = CourseExt.where(:course_id => @context.id).first
  #   if course_ext
  #     kvd = course_ext.isu_tblvdkr_id
  #     att_kvd = course_ext.isu_tblvdtkr_id
  #   end
  #   unless kvd
  #     return render :json => {:error => 'invalid course ID'}, status: :bad_request
  #   end
  #   locale = @current_user.locale
  #   locale ||= @domain_root_account.default_locale
  #   if locale == "en"
  #     locale = @domain_root_account.default_locale
  #   end
  #   course_students_points = UchprocPointJournal.course_students_points(kvd, att_kvd, locale)
  #   count_lessons = UchprocTopic.get_count_lessons(att_kvd)
  #   study_weeks = UchprocAcademicPlan.season_study_weeks(course_students_points[:academic_plan_id],
  #                                                        course_students_points[:class_number],
  #                                                        count_lessons,
  #                                                        @context.id,
  #                                                        @current_user)
  #   if study_weeks.include?(:errors)
  #     render :json => {:error => study_weeks[:errors].join("', '")}, status: :bad_request
  #   else
  #     render :json => students_points_journal_json(course_students_points[:points], study_weeks,
  #                                                  @current_user, @sessions, [])
  #   end

  # end

  # def update_week_points
  #   get_context
  #   week_number = params[:week_number]
  #   current_week_number = UchprocAcademicYear.current_week_number(@context.id)
  #   unless @current_user.can_access_week?(@context, week_number, current_week_number == week_number) || @current_user.can_access_week?(@context.account, week_number, current_week_number == week_number)
  #     render :json => {error: 'You do not have permissions for this week'}, status: :bad_request
  #     return
  #   end
  #   course_ext = CourseExt.where(:course_id => @context.id).first
  #   if course_ext
  #     kvd = course_ext.isu_tblvdkr_id
  #     att_kvd = course_ext.isu_tblvdtkr_id
  #   end
  #   unless kvd
  #     return render :json => {:error => 'Invalid course ID'}, status: :bad_request
  #   end
  #   journal_point_type = @context.journal_point_type

  #   locale = @current_user.locale
  #   locale ||= @domain_root_account.default_locale
  #   if locale == "en"
  #     locale = @domain_root_account.default_locale
  #   end

  #   if !params[:week_number].present? || !params[:students_points].present?
  #     render :json => {error: 'invalid week_number or students_points'}, status: :bad_request
  #     return
  #   end

  #   count_lessons = UchprocTopic.get_count_lessons(att_kvd)
  #   academic_plan_and_class = UchprocPointJournal.course_academic_plan_class(kvd)
  #   season_study_weeks = UchprocAcademicPlan.season_study_weeks(academic_plan_and_class[:academic_plan_id],
  #                                                               academic_plan_and_class[:class_number], count_lessons, @context.id, @current_user)

  #   if season_study_weeks.include?(:errors)
  #     render :json => {:error => season_study_weeks[:errors].join("', '")}, status: :bad_request
  #     return
  #   end
  #   students_points = params[:students_points]
  #   bad_request = false
  #   points = UchprocPointJournal.where(kvd: kvd)
  #   students_points.map do |student_points|
  #     if !student_points[:studentId].present? ||
  #       !student_points[:weekPoint][:point].present? ||
  #       !student_points[:weekPoint][:divided].present?
  #       bad_request = true
  #       render :json => {error: 'invalid student points data'}, status: :bad_request
  #       return
  #     end
  #     student_id = student_points[:studentId]
  #     divided = student_points[:weekPoint][:divided]
  #     divided_array = [
  #       divided[:lecture_att].to_f, 0.0, divided[:practical_att].to_f, divided[:practical_act].to_f,
  #       divided[:KMDRO_att].to_f, divided[:KMDRO_act].to_f, 0.0, divided[:KMD].to_f, 0.0, 0.0
  #     ]
  #     point = student_points[:weekPoint][:point].to_f
  #     unless UchprocPointJournal.correct_student_week_point?(season_study_weeks, point, divided_array, journal_point_type)
  #       bad_request = true
  #       render :json => {error: 'not correct week point'}, status: :bad_request
  #       return
  #     end
  #     divided_string = divided_array.map{ |el| UchprocPointJournal.float_point_to_string(el)}.join(" ")
  #     student_points = nil
  #     points.map do |student|
  #       if student_id.to_s == student[:kst].to_s
  #         student_points = student
  #         break
  #       end
  #     end

  #     if student_points && (student_points["mcocer#{week_number}"] != divided_string ||  student_points["oceblkr#{week_number}"] != UchprocPointJournal.float_point_to_string(point))
  #       student_points["oceblkr#{week_number}"] = UchprocPointJournal.float_point_to_string(point)
  #       student_points["mcocer#{week_number}"] = divided_string
  #       UchprocPointJournal.recount_results_and_assessment(student_points, season_study_weeks, @context.id, current_week_number)
  #     end

  #   end
  #   if bad_request
  #     render :json => {error: 'invalid request'}, status: :bad_request
  #   else
  #     course_students_points = UchprocPointJournal.course_students_points(kvd, att_kvd, locale)
  #     render :json => students_points_journal_json(course_students_points[:points], season_study_weeks,
  #                                                  @current_user, @sessions, [])
  #   end
  # end

  def student_points_update
    get_context
    week_number = params[:week_number]
    current_week_number = UchprocAcademicYear.current_week_number(@context.id)
    unless @current_user.can_access_week?(@context, week_number, current_week_number == week_number) || @current_user.can_access_week?(@context.account, week_number, current_week_number == week_number)
      render :json => {error: 'You do not have permissions for this week'}, status: :bad_request
      return
    end
    student_id = params[:student_id]
    course_ext = CourseExt.where(:course_id => @context.id).first
    journal_point_type = @context.journal_point_type
    if course_ext
      kvd = course_ext.isu_tblvdkr_id
      att_kvd = course_ext.isu_tblvdtkr_id
    end
    unless kvd
      return render :json => {:error => 'invalid course ID'}, status: :bad_request
    end
    points = UchprocPointJournal.where(kvd: kvd, kst: student_id).first
    unless points
      return render :json => {:error => "The record line for this student for this course was not found. Please contact your administrator."}, status: :bad_request
    end
    count_lessons = UchprocTopic.get_count_lessons(att_kvd)
    academic_plan_and_class = UchprocPointJournal.course_academic_plan_class(kvd)
    season_study_weeks = UchprocAcademicPlan.season_study_weeks(academic_plan_and_class[:academic_plan_id],
                                                                academic_plan_and_class[:class_number], count_lessons, @context.id, @current_user)
    if season_study_weeks.include?(:errors)
      render :json => {:error => season_study_weeks[:errors].join("', '")}, status: :bad_request
      return
    end
    if student_id
      point = params[:point]
      lecture_att = params[:divided][:lecture_att]
      practical_att = params[:divided][:practical_att]
      practical_act = params[:divided][:practical_act]
      kmdro_act = params[:divided][:KMDRO_act]
      kmdro_att = params[:divided][:KMDRO_att]
      kmd = params[:divided][:KMD]
      if point  && lecture_att  && practical_att  &&
        practical_act && kmdro_att && kmdro_act && kmd
        divided_array = [
          lecture_att.to_f, 0.0, practical_att.to_f, practical_act.to_f,
          kmdro_att.to_f, kmdro_act.to_f, 0.0, kmd.to_f, 0.0, 0.0
        ]

        unless UchprocPointJournal.correct_student_week_point?(season_study_weeks, point, divided_array, journal_point_type)
          bad_request = true
          render :json => {error: 'incorrect student points data'}, status: :bad_request
          return
        end
        week_number = params[:week_number]
        unless week_number
          return render :json => {error: 'incorrect week number'}, status: :bad_request
        end
        current_week_number = UchprocAcademicYear.current_week_number(@context.id)
        if week_number > current_week_number
          render :json => {error: 'You do not have permissions for this week'}, status: :bad_request
          return
        end
        if week_number.to_i < 1 || week_number > 18
          return render :json => {error: "week number #{week_number} not found"}, status: :bad_request
        end
        if week_number > UchprocAcademicYear.current_week_number(@context.id)
          render :json => {error: 'You do not have permissions for this week'}, status: :bad_request
          return
        end
        divided_string = divided_array.map{ |el| UchprocPointJournal.float_point_to_string(el)}.join(" ")
        points.update({"oceblkr#{week_number}": UchprocPointJournal.float_point_to_string(point), "mcocer#{week_number}": divided_string})
        points.back_recount_results_and_assessment(points, season_study_weeks, @context.id, current_week_number)
      else
        return render :json => {:error => 'invalid data'}, status: :bad_request
      end
      return render  :json => {:week_number => week_number, :point => point, :divided => {:lecture_att => lecture_att,
                                                                                          :practical_att => practical_att, :practical_act => practical_act, :KMDRO_att => kmdro_att,
                                                                                          :KMDRO_act => kmdro_act, :KMD => kmd}}
    else
      return render :json => {:error => "invalid student ID #{student_id}"}, status: :bad_request
    end
  end

  def my_points
    get_context
    return unless authorized_action(@context, @current_user, [:student_points])
    sis_user_id = @current_user.pseudonyms.where("sis_user_id like 'std_%'").first.sis_user_id
    student_id = sis_user_id[4..sis_user_id.length]
    course_ext = CourseExt.where(:course_id => @context.id).first
    if course_ext
      point_kvd = course_ext.isu_tblvdkr_id
      att_kvd = course_ext.isu_tblvdtkr_id
    end
    unless point_kvd
      return render :json => {:error => 'invalid course ID'}, status: :bad_request
    end
    course_student_points = UchprocPointJournal.course_student_points(point_kvd, student_id)
    study_weeks = UchprocAcademicPlan.season_study_weeks(course_student_points[:academic_plan_id],
                                                         course_student_points[:class_number], @context.id, @current_user)
    json = student_points_journal_json(course_student_points[:points],
                                       study_weeks[:rating_week_count],
                                       study_weeks[:week_numbers])
    header = study_weeks[:header]
    json[:max_week_point] = header[:max_week_point]
    json[:max_lecture_att] = header[:max_lecture_att]
    json[:max_practical_att] = header[:max_practical_att]
    json[:max_practical_act] = header[:max_practical_act]
    json[:max_KMDRO_att] = header[:max_KMDRO_att]
    json[:max_KMDRO_act] = header[:max_KMDRO_act]
    json[:max_KMD] = header[:max_KMD]
    render :json => json
  end
end

