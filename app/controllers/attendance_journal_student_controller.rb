class AttendanceJournalStudentController < ApplicationController
  before_action :require_user
  def my_attendance
    get_context
    return unless authorized_action(@context, @current_user, [:student_points])
    sis_user_id = @current_user.pseudonyms.where("sis_user_id like 'std_%'").first.sis_user_id
    student_id = sis_user_id[4..-1]
    course_id = params[:course_id]
    course_ext = CourseExt.where(:course_id => course_id).first
    if course_ext
      point_kvd = course_ext.isu_tblvdkr_id
      att_kvd = course_ext.isu_tblvdtkr_id
    end
    unless att_kvd
      return render :json => {:error => 'invalid course ID'}, status: :bad_request
    end

    att_row = IsuStdAttendance.where("kvd =? AND kst =?", att_kvd, student_id).first
    topics = IsuTema.where("kvd =?", att_kvd)
    current_terms = @domain_root_account.
      enrollment_terms.
      active.
      where("(start_at<=? OR start_at IS NULL) AND (end_at >=? OR end_at IS NULL) AND NOT (start_at IS NULL AND end_at IS NULL)", Time.now.utc, Time.now.utc).
      limit(2).
      to_a
    @current_term = current_terms.length == 1 ? current_terms.first : nil
    render :json => attendance_by_weeks_by_topics(topics, att_row)
  end

  def attendance_by_weeks_by_topics(topics, attendance_row)
    count_att_in_weeks = []
    (1..18).each do |i|
      count_att_in_weeks << {
        :week_number => i,
        :count_N => 0,
        :count_B => 0,
        :count_I => 0,
        :count_X => 0,
        :count_Y => 0
      }
    end
    totals = {
      :count_N => 0,
      :count_B => 0,
      :count_I => 0,
      :count_X => 0,
      :count_Y => 0
    }
    att_by_topic = []
    topics.map do |topic|
      topic_row_number = topic.cnzap.to_i
      if topic_row_number > 0 && topic_row_number < 97
        count_day = ((topic.dtzap - @current_term.start_at)/86400).to_i
        # logger.info "Count Day Is: #{count_day}"
        k = count_day % 7 == 0? 0 : 1
        week = (count_day / 7).to_i + k
        column_name = "cpos#{topic_row_number}"
        absent = attendance_row[column_name]
        absent = absent.strip
        if week < 19 && absent == 'н'
          count_att_in_weeks[week - 1][:count_N] = count_att_in_weeks[week - 1][:count_N] + topic.nkolchv.to_i
          totals[:count_N] = totals[:count_N] + topic.nkolchv.to_i
        end
        if week < 19 && absent == 'б'
          count_att_in_weeks[week - 1][:count_B] = count_att_in_weeks[week - 1][:count_B] + topic.nkolchv.to_i
          totals[:count_B] = totals[:count_B] + topic.nkolchv.to_i
        end
        if week < 19 && absent == 'и'
          count_att_in_weeks[week - 1][:count_I] = count_att_in_weeks[week - 1][:count_I] + topic.nkolchv.to_i
          totals[:count_I] = totals[:count_I] + topic.nkolchv.to_i
        end
        if week < 19 && absent == 'х'
          count_att_in_weeks[week - 1][:count_X] = count_att_in_weeks[week - 1][:count_X] + topic.nkolchv.to_i
          totals[:count_X] = totals[:count_X] + topic.nkolchv.to_i
        end
        if week < 19 && absent == 'у'
          count_att_in_weeks[week - 1][:count_Y] = count_att_in_weeks[week - 1][:count_Y] + topic.nkolchv.to_i
          totals[:count_Y] = totals[:count_Y] + topic.nkolchv.to_i
        end
        att_by_topic << {
          :topic_name => topic.ctema,
          :topic_number => topic_row_number,
          :topic_date => topic.dtzap,
          :attendance_type => absent,
          :lecture_count => topic.nkolch.to_i,
          :practical_count => topic.nkolchprak.to_i,
          :seminar_count => topic.nkolchsem.to_i,
          :laboratory_count => topic.nkolchlab.to_i,
          :kmdro_count => topic.nkolchkmdro.to_i
        }
      end
    end
    {
      :by_weeks => count_att_in_weeks,
      :by_topics => att_by_topic,
      :totals => totals
    }
  end

  def index
    @student_attendance = []
    if @current_user.can_access_any_account_journals?([:student_attendance]) || @current_user.can_access_any_course_journals?([:student_attendance])
      if sis = @current_user.pseudonym.sis_user_id
        sis_id = nil
        if sis.length > 4
          std_id = sis[4..-1]
        end
        current_terms = @domain_root_account.
          enrollment_terms.
          active.
          where("(start_at<=? OR start_at IS NULL) AND (end_at >=? OR end_at IS NULL) AND NOT (start_at IS NULL AND end_at IS NULL)", Time.now.utc, Time.now.utc).
          limit(2).
          to_a
        @current_term = current_terms.length == 1 ? current_terms.first : nil
        courses = @current_user.all_courses_for_active_enrollments.for_term(@current_term)
        courses.map do |course|
          teachers = course.teachers
          teachers_name = ""
          teachers.map do |teacher|
            teachers_name += teacher.name
          end
          if cext = course.course_ext
            kvd = cext.isu_tblvdtkr_id
            att_row = IsuStdAttendance.where("kvd =? AND kst =?", kvd, std_id).first
            topics = IsuTema.where("kvd =?", kvd)
            weeks_attendance = count_absent_in_week(topics, att_row)
            @student_attendance << {:course_name => course.name, :teachers => teachers_name,
                                    :attendance => weeks_attendance}
            logger.info "Student attendance is #{{:student_attendance => @student_attendance}}"
          end
        end
      end
    else
      render "shared/unauthorized", status: :unauthorized, content_type: Mime::Type.lookup('text/html'), formats: :html
    end

    #users
  end
  def count_absent_in_week(topics, att_row)
    count_kred_in_week = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    topics.map do |topic|
      topic_row_number = topic.cnzap.to_i
      if topic_row_number > 0 && topic_row_number < 97
        count_day = ((topic.dtzap - @current_term.start_at)/86400).to_i
        # logger.info "Count Day Is: #{count_day}"
        k = count_day % 7 > 0? 1 : 0
        week = (count_day / 7).to_i + k
        column_name = "cpos#{topic_row_number}"
        absent = att_row[column_name]
        absent = absent.strip
        if week < 19 && absent == 'н'
          count_kred_in_week[week - 1] = count_kred_in_week[week - 1] + topic.nkolchv.to_i
        end
      end
    end
    count_kred_in_week
  end

  def attendance

  end
end

