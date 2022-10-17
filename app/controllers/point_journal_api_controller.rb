class PointJournalApiController < ApplicationController
  before_action :require_user
  include Api::V1::PointJournal
  def main_filter

    roles = {
      :admin => 'AccountAdmin',
      :advisor => 'AccountAdvisor',
      :teacher => 'TeacherEnrollment'
    }
    role_admin = Role.get_built_in_role('AccountAdmin', root_account_id: @domain_root_account.id)
    role_advisor = Role.where("name = ? AND workflow_state = ? AND root_account_id = ?", roles[:advisor], 'active', @domain_root_account.id).first
    account_fak_ids = [0]
    account_spe_ids = [0]
    account_krs_ids = [0]
    account_grp_ids = [0]
    all_accounts = false
    admin_accounts = @current_user.account_users.active.where(:role_id => role_admin.id)
    advisor_accounts = nil
    if role_advisor
      advisor_accounts = @current_user.account_users.active.where(:role_id => role_advisor.id)
    end
    if advisor_accounts && advisor_accounts.length > 0
      admin_accounts += advisor_accounts
      admin_accounts.flatten!
    end
    admin_accounts.map do |admin_account|
      account = admin_account.account
      if account
        unless account.parent_account_id
          all_accounts = true
          break admin_account
        end
        if account.sis_source_id
          if account.sis_source_id.start_with?("fak_")
            account_fak_ids << account.id
          elsif account.sis_source_id.start_with?("spe_")
            account_spe_ids << account.id
          elsif account.sis_source_id.start_with?("krs_")
            account_krs_ids << account.id
          elsif account.sis_source_id.start_with?("grp_")
            account_grp_ids << account.id
          end
        end
      end
    end
    if all_accounts
      data = Account.active
                    .joins("INNER JOIN account_exts as fak_ext ON accounts.id = fak_ext.account_id
                  INNER JOIN accounts AS spe ON accounts.id = spe.parent_account_id
                  INNER JOIN account_exts as spe_ext ON spe.id = spe_ext.account_id
                  INNER JOIN accounts AS krs ON spe.id = krs.parent_account_id
                  INNER JOIN accounts AS grp ON krs.id = grp.parent_account_id
                  INNER JOIN isu_grp  ON 'grp_'||isu_grp.kdn = grp.sis_source_id"
                    )
                    .where("accounts.sis_source_id LIKE 'fak_%' AND spe.sis_source_id LIKE 'spe_%'
                  AND krs.sis_source_id LIKE 'krs_%' AND grp.sis_source_id LIKE 'grp_%' AND
                  spe.workflow_state<>'deleted' AND krs.workflow_state<>'deleted' AND grp.workflow_state<>'deleted'")
                    .select("accounts.id as isu_fak_id, fak_ext.code as kfk, accounts.name as fak_name, spe.id as isu_spe_id, spe_ext.code as ksp,
                  spe.name as spe_name, krs.id as isu_krs_id, krs.name as kkr, grp.id as isu_grp_id, grp.name as kgr, rtrim(shgrp) as code_group")
                    .order("kfk, ksp, kkr, kgr")
    else
      current_terms = @domain_root_account.
        enrollment_terms.
        active.
        where("(start_at<=? OR start_at IS NULL) AND (end_at >=? OR end_at IS NULL) AND NOT (start_at IS NULL AND end_at IS NULL)", Time.now.utc, Time.now.utc).
        limit(2).
        to_a
      current_term = current_terms.length == 1 ? current_terms.first : nil
      if current_term
        ids = [@current_user.id]
        courses = Course.active.by_teachers_or_assistants(ids).for_term(current_term)
        courses.map do |course|
          account_grp_ids << course.account_id
        end
      end
      data = Account.active
                    .joins("INNER JOIN account_exts as fak_ext ON accounts.id = fak_ext.account_id
                  INNER JOIN accounts AS spe ON accounts.id = spe.parent_account_id
                  INNER JOIN account_exts as spe_ext ON spe.id = spe_ext.account_id
                  INNER JOIN accounts AS krs ON spe.id = krs.parent_account_id
                  INNER JOIN accounts AS grp ON krs.id = grp.parent_account_id
                  INNER JOIN isu_grp  ON 'grp_'||isu_grp.kdn = grp.sis_source_id")
                    .where("accounts.sis_source_id LIKE 'fak_%' AND spe.sis_source_id LIKE 'spe_%'
                  AND krs.sis_source_id LIKE 'krs_%' AND grp.sis_source_id LIKE 'grp_%' AND
                  spe.workflow_state<>'deleted' AND krs.workflow_state<>'deleted' AND grp.workflow_state<>'deleted'
                  AND (accounts.id IN (?) OR spe.id IN (?) OR krs.id IN (?) OR grp.id IN (?))", account_fak_ids, account_spe_ids, account_krs_ids, account_grp_ids )
                    .select("accounts.id as isu_fak_id, fak_ext.code as kfk, accounts.name as fak_name, spe.id as isu_spe_id, spe_ext.code as ksp,
                  spe.name as spe_name, krs.id as isu_krs_id, krs.name as kkr, grp.id as isu_grp_id, grp.name as kgr, rtrim(shgrp) as code_group")
                    .order("kfk, ksp, kkr, kgr")
    end
    render :json => point_journal_header_json_old(data, @current_user, @sessions, [])
  end

  def points
    get_context
    course_ext = CourseExt.where(:course_id => @context.id).first
    if course_ext
      kvd = course_ext.isu_tblvdkr_id
      att_kvd = course_ext.isu_tblvdtkr_id
    end
    unless kvd
      return render :json => {:error => 'invalid course ID'}, status: :bad_request
    end
    locale = @current_user.locale
    locale ||= @domain_root_account.default_locale
    if locale == "en"
      locale = @domain_root_account.default_locale
    end
    course_students_points = UchprocPointJournal.course_students_points(kvd, att_kvd, locale)
    count_lessons = UchprocTopic.get_count_lessons(att_kvd)
    study_weeks = UchprocAcademicPlan.season_study_weeks(course_students_points[:academic_plan_id],
                                                         course_students_points[:class_number],
                                                         count_lessons,
                                                         @context.id,
                                                         @current_user)
    if study_weeks.include?(:errors)
      render :json => {:error => study_weeks[:errors].join("', '")}, status: :bad_request
    else
      render :json => students_points_journal_json(course_students_points[:points], study_weeks,
                                                   @current_user, @sessions, [])
    end

  end

  def update_week_points
    get_context
    week_number = params[:week_number]
    current_week_number = UchprocAcademicYear.current_week_number(@context.id)
    unless @current_user.can_access_week?(@context, week_number, current_week_number == week_number) || @current_user.can_access_week?(@context.account, week_number, current_week_number == week_number)
      render :json => {error: 'You do not have permissions for this week'}, status: :bad_request
      return
    end
    course_ext = CourseExt.where(:course_id => @context.id).first
    if course_ext
      kvd = course_ext.isu_tblvdkr_id
      att_kvd = course_ext.isu_tblvdtkr_id
    end
    unless kvd
      return render :json => {:error => 'Invalid course ID'}, status: :bad_request
    end
    journal_point_type = @context.journal_point_type

    locale = @current_user.locale
    locale ||= @domain_root_account.default_locale
    if locale == "en"
      locale = @domain_root_account.default_locale
    end

    if !params[:week_number].present? || !params[:students_points].present?
      render :json => {error: 'invalid week_number or students_points'}, status: :bad_request
      return
    end

    count_lessons = UchprocTopic.get_count_lessons(att_kvd)
    academic_plan_and_class = UchprocPointJournal.course_academic_plan_class(kvd)
    season_study_weeks = UchprocAcademicPlan.season_study_weeks(academic_plan_and_class[:academic_plan_id],
                                                                academic_plan_and_class[:class_number], count_lessons, @context.id, @current_user)

    if season_study_weeks.include?(:errors)
      render :json => {:error => season_study_weeks[:errors].join("', '")}, status: :bad_request
      return
    end
    students_points = params[:students_points]
    bad_request = false
    points = UchprocPointJournal.where(kvd: kvd)
    students_points.map do |student_points|
      if !student_points[:studentId].present? ||
        !student_points[:weekPoint][:point].present? ||
        !student_points[:weekPoint][:divided].present?
        bad_request = true
        render :json => {error: 'invalid student points data'}, status: :bad_request
        return
      end
      student_id = student_points[:studentId]
      divided = student_points[:weekPoint][:divided]
      divided_array = [
        divided[:lecture_att].to_f, 0.0, divided[:practical_att].to_f, divided[:practical_act].to_f,
        divided[:KMDRO_att].to_f, divided[:KMDRO_act].to_f, 0.0, divided[:KMD].to_f, 0.0, 0.0
      ]
      point = student_points[:weekPoint][:point].to_f
      unless UchprocPointJournal.correct_student_week_point?(season_study_weeks, point, divided_array, journal_point_type)
        bad_request = true
        render :json => {error: 'not correct week point'}, status: :bad_request
        return
      end
      divided_string = divided_array.map{ |el| UchprocPointJournal.float_point_to_string(el)}.join(" ")
      student_points = nil
      points.map do |student|
        if student_id.to_s == student[:kst].to_s
          student_points = student
          break
        end
      end

      if student_points && (student_points["mcocer#{week_number}"] != divided_string ||  student_points["oceblkr#{week_number}"] != UchprocPointJournal.float_point_to_string(point))
        student_points["oceblkr#{week_number}"] = UchprocPointJournal.float_point_to_string(point)
        student_points["mcocer#{week_number}"] = divided_string
        UchprocPointJournal.recount_results_and_assessment(student_points, season_study_weeks, @context.id, current_week_number)
      end

    end
    if bad_request
      render :json => {error: 'invalid request'}, status: :bad_request
    else
      course_students_points = UchprocPointJournal.course_students_points(kvd, att_kvd, locale)
      render :json => students_points_journal_json(course_students_points[:points], season_study_weeks,
                                                   @current_user, @sessions, [])
    end
  end

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

