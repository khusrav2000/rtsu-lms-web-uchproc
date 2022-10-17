class TimetableApiController < ApplicationController
  before_action :require_user
  before_action :get_context

  include Api::V1::IsuTimetable



  def index
    data = UchprocSpecialty.all
    render :json => isu_speces_json(data, @current_user, @sessions, [])
  end

  def show
    account_id = params[:grp_id]
    @account = Account.find(account_id)
    academic_year = UchprocAcademicYear.all.first
    @last_season_name = academic_year.last_season_name
    current_terms = @domain_root_account.
      enrollment_terms.
      active.
      where("(start_at<=? OR start_at IS NULL) AND (end_at >=? OR end_at IS NULL) AND NOT (start_at IS NULL AND end_at IS NULL)", Time.now.utc, Time.now.utc).
      limit(2).
      to_a
    @current_term = current_terms.length == 1 ? current_terms.first : nil
    if @account && @current_term
      group_id = @account.sis_source_id[4..-1]
      @code_timetable = code_uchproc_timetable(group_id)
      courses = Course.active.for_term(@current_term)
                      .joins(:course_ext).select("courses.id, courses.name, course_exts.kolkr, count(isu_tblrlstzkrst.id_zkrst)")
                      .joins("INNER JOIN isu_tblvdtkr ON isu_tblvdtkr.isu_tblvdtkr_id = course_exts.isu_tblvdtkr_id")
                      .joins("INNER JOIN isu_tblrlstzkr ON isu_tblvdtkr.kst = isu_tblrlstzkr.kst AND isu_tblvdtkr.kpr = isu_tblrlstzkr.kpr AND isu_tblvdtkr.chruchgod = isu_tblrlstzkr.chruchgod")
                      .joins("LEFT JOIN isu_tblrlstzkrst ON isu_tblrlstzkrst.id_zkrst = isu_tblrlstzkr.kdn AND isu_tblrlstzkrst.isactive ='Y'")
                      .where("courses.account_id = ? AND isu_tblrlstzkr.krs=? ", @account.id, @code_timetable)
                      .group("courses.id, courses.name, course_exts.kolkr")

      course_info = course_info(courses, group_id)
      timetable = Course.active.for_term(@current_term)
                        .joins(:course_ext)
                        .joins("INNER JOIN isu_tblvdtkr ON isu_tblvdtkr.isu_tblvdtkr_id = course_exts.isu_tblvdtkr_id")
                        .joins("INNER JOIN isu_tblrlstzkr ON isu_tblvdtkr.kst = isu_tblrlstzkr.kst AND isu_tblvdtkr.kpr = isu_tblrlstzkr.kpr AND isu_tblvdtkr.chruchgod = isu_tblrlstzkr.chruchgod")
                        .joins("INNER JOIN isu_tblrlstzkrst ON isu_tblrlstzkrst.id_zkrst = isu_tblrlstzkr.kdn")
                        .select("courses.id, courses.name, course_exts.kolkr, isu_tblrlstzkrst.cday, isu_tblrlstzkrst.cmesto,isu_tblrlstzkrst.ctime,
                                isu_tblrlstzkrst.cvidzn, isu_tblrlstzkrst.isu_tblrlstzkrst_id as timetable_id, isu_tblrlstzkr.kst as sot_id")
                        .where("courses.account_id = ? AND isu_tblrlstzkr.krs=? AND isu_tblrlstzkrst.isactive ='Y'", @account.id, @code_timetable)

    end
    render :json => isu_timetable_json(course_info, timetable, @current_user, @sessions, [])

  end


  def create
    @err= []
    calendar_timetable = {}
    array_weeks_name = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].freeze
    account_id = params[:grp_id]
    @account = Account.find(account_id)
    academic_year = UchprocAcademicYear.all.first
    @last_season_name = academic_year.last_season_name
    if @account && @last_season_name
      group_id = @account.sis_source_id[4..-1]
      @code_timetable = code_uchproc_timetable(group_id)
    end
    if @code_timetable
      data = params[:data]
      data.map do |item|
        if check_params(item)
          if add_lesson(item)
            times = convert_start_and_end_at(item[:time])
            location_name = item[:classroom_number] + " (#{format_class_type(item[:class_type])})"
            timetable = ActionController::Parameters.new({
                                                           weekdays: array_weeks_name[item[:week_day].to_i - 1],
                                                           start_time: times[:start_at], end_time: times[:end_at], location_name: location_name
                                                         })
            timetable_data = ActionController::Parameters.new({timetables: ActionController::Parameters.new(
              {all: [timetable]})})

            if calendar_timetable[item[:course_id]]
              calendar_timetable[item[:course_id]][:timetables][:all]<< timetable
            else
              calendar_timetable[item[:course_id]] = timetable_data
            end
            #add_to_event_calendar(timetable_data, course)

          end
        else
          @err << "Params not correct"
        end
      end
      calendar_timetable.map do |course_id, event|
        course = Course.find(course_id)
        if course
          add_to_event_calendar(event, course)
        end
      end
    else
      @err << "Uchproc code timetable not found"
    end

    if @err && @err.length != 0
      logger.info "Request errors #{{:errors => @err}}"
      render json: { error: @err }, status: 400
    else
      render json: {message: "Timetable saved successful"}, status: 200
    end
  end


  def destroy

  end

  def validation(group_id, subject_id, teacher_id, academic_year)
    return true
  end

  def course_info(courses, account_id)
    data = []
    courses.map do |course|
      teachers_data = []
      teachers = course.teachers
      teachers.map do |teacher|
        teacher_pseudonym = teacher.pseudonym
        sot_id = get_uchproc_sot_id(teacher_pseudonym)
        teachers_data << {:teacher_id => teacher.id, :teacher_name => teacher.name, :sot_id => sot_id}
      end
      ta_enrollments = course.ta_enrollments
      ta_enrollments.map do |ta_enrollment|
        teacher_assistent = ta_enrollment.user
        assistent_pseudonym = teacher_assistent.pseudonym
        sot_id = get_uchproc_sot_id(assistent_pseudonym)
        teachers_data << {:teacher_id => teacher_assistent.id, :teacher_name => teacher_assistent.name, :sot_id =>sot_id}
      end

      data << {:group_id => account_id, :course_name => course.name, :teachers => teachers_data, :course_id => course.id, :kolkr => course.kolkr, :count => course.count}
    end
    data
  end
  def get_uchproc_sot_id(teacher_pseudonym)
    sis_user_id = teacher_pseudonym.sis_user_id
    uchproc_sot_id = 0
    if sis_user_id.length > 4
      uchproc_sot_id = sis_user_id[4..-1].to_i
    end
    uchproc_sot_id
  end

  def code_uchproc_timetable(group_id)
    header_timetable = IsuTimetableKrs.select("isu_tblrlzgzkr.kdn").where("isu_tblrlzgzkr.kgr =? AND isu_tblrlzgzkr.chruchgod =?", group_id, @last_season_name).first
    if header_timetable
      return header_timetable.kdn
    else
      return 0
    end

  end

  def add_lesson(item)
    course_info = Course.active
                        .joins(:course_ext).select("isu_tblvdtkr.kst, isu_tblvdtkr.kas, isu_tblvdtkr.kpr")
                        .joins("INNER JOIN isu_tblvdtkr ON isu_tblvdtkr.isu_tblvdtkr_id = course_exts.isu_tblvdtkr_id")
                        .where("courses.id =?", item[:course_id]).first
    teacher_and_subject = nil
    if course_info
      teacher_and_subject = IsuTimetableGrp.where("isu_tblrlstzkr.krs = ? AND isu_tblrlstzkr.kpr = ? AND (isu_tblrlstzkr.kst = ? OR isu_tblrlstzkr.kas = ?)",@code_timetable,course_info.kpr, course_info.kst , course_info.kas).first
    end

    if teacher_and_subject && teacher_id = item[:teacher_id]
      teacher = User.where(:id => teacher_id).first
      if teacher
        teacher_pseudonym = teacher.pseudonym
      end
      if teacher_pseudonym
        uchproc_sot_id = get_uchproc_sot_id(teacher_pseudonym)
        time = convert_int_to_time(item[:time])
        class_type = format_class_type(item[:class_type])
        week_day = item[:week_day].to_i
        if week_day && (week_day > 7 || week_day < 1)
          @err << "Week day not in 1..7"
          return false
        else
          s_week_day = "0" + week_day.to_s
        end
        if time != "-1" && s_week_day && (uchproc_sot_id == course_info.kst || uchproc_sot_id == course_info.kas)
          if uchproc_sot_id != teacher_and_subject.kst && uchproc_sot_id != 0
            teacher_and_subject.kst = uchproc_sot_id
            teacher_and_subject.save
          end
          timetable_id = item[:timetable_id]
          if timetable_id
            old_lesson = IsuTimetable.where(:isu_tblrlstzkrst_id => timetable_id).first
            if old_lesson
              if old_lesson.ctime != time || old_lesson.cday != s_week_day
                old_lesson.isactive = 'N'
                lesson = IsuTimetable.new(:cday => s_week_day,  :ctime => time, :chruchgod =>teacher_and_subject.chruchgod, :cvidzn =>class_type, :isactive => 'Y')
              elsif old_lesson.cmesto != item[:classroom_number] || old_lesson.cvidzn != class_type
                old_lesson.cmesto = item[:classroom_number]
                old_lesson.cvidzn = class_type
                old_lesson.save!
              end
            else
              lesson = IsuTimetable.new(:cday => s_week_day,  :ctime => time, :chruchgod =>teacher_and_subject.chruchgod, :cvidzn =>class_type, :isactive => 'Y')
            end
          end
          if lesson
            lesson.cmesto = item[:classroom_number]
            lesson.id_zkrst = teacher_and_subject.kdn
            if lesson.save
              lesson[:id] = lesson.id
              if old_lesson
                old_lesson.save!
              end
              lesson.save!
            else
              @err << "Can't save lesson with kpr for #{{:item => item}}"
              return false
            end
          end
        else
          @err << "Can't response time for #{{:item => item}}"
          return false
        end
      else
        @err << "Teacher not found by ID= #{item[:teacher_id]}"
        return false
      end
    else
      @err << "Teacher ID not found #{{:item => item}}"
      return false
    end
    return true
  end

  def add_to_event_calendar(params, course)
    timetable_data = params[:timetables].to_unsafe_h
    logger.info "Request errors #{{:timetable_data => timetable_data}}"
    builders = {}
    updated_section_ids = []
    timetable_data.each do |section_id, timetables|
      timetable_data[section_id] = Array(timetables)
      section = section_id == 'all' ? nil : api_find(course.active_course_sections, section_id)
      updated_section_ids << section.id if section

      builder = Courses::TimetableEventBuilder.new(course: course, course_section: section)
      builders[section_id] = builder

      builder.process_and_validate_timetables(timetables)
      if builder.errors.present?
        logger.info "Timetable #{timetables}"
        logger.info "Builder has error #{{:message => builder.errors}}"
        logger.info "Builder has error!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        return false
      end
    end

    course.timetable_data = timetable_data # so we can retrieve it later
    course.save!

    timetable_data.each do |section_id, timetables|
      builder = builders[section_id]
      event_hashes = builder.generate_event_hashes(timetables)
      builder.process_and_validate_event_hashes(event_hashes)
      raise "error creating timetable events #{builder.errors.join(", ")}" if builder.errors.present?
      builder.send_later(:create_or_update_events, event_hashes) # someday we may want to make this a trackable progress job /shrug
    end

    # delete timetable events for sections missing here
    ignored_section_ids = course.active_course_sections.where.not(:id => updated_section_ids).pluck(:id)
    if ignored_section_ids.any?
      CalendarEvent.active.for_timetable.where(:context_type => "CourseSection", :context_id => ignored_section_ids).
        update_all(:workflow_state => 'deleted', :deleted_at => Time.now.utc)
    end

    return true
  end
  def check_params(data)
    if data[:course_id] && data[:week_day] && data[:time]
      return true
    else
      return false
    end
  end

  def convert_start_and_end_at(time)
    case time
    when 0
      return {:start_at => "08:00 am", :end_at => "08:50 am"}.to_hash
    when 1
      return {:start_at => "09:00 am", :end_at => "09:50 am"}.to_hash
    when 2
      return {:start_at => "10:00 am", :end_at => "10:50 am"}.to_hash
    when 3
      return {:start_at => "11:00 am", :end_at => "11:50 am"}.to_hash
    when 4
      return {:start_at => "00:00 pm", :end_at => "00:50 pm"}.to_hash
    when 5
      return {:start_at => "01:00 pm", :end_at => "01:50 pm"}.to_hash
    when 6
      return {:start_at => "02:00 pm", :end_at => "02:50 pm"}.to_hash
    when 7
      return {:start_at => "03:00 pm", :end_at => "03:50 pm"}.to_hash
    when 8
      return {:start_at => "04:00 pm", :end_at => "04:50 pm"}.to_hash
    when 9
      return {:start_at => "05:00 pm", :end_at => "05:50 pm"}.to_hash
    when 10
      return {:start_at => "06:00 pm", :end_at => "06:50 pm"}.to_hash
    when 11
      return {:start_at => "07:00 pm", :end_at => "07:50 pm"}.to_hash
    else
      return {:start_at => "-1", :end_at => "-1"}
    end
  end
  def convert_int_to_time(time)
    case time
    when 0
      return "08:00-08:50"
    when 1
      return "09:00-09:50"
    when 2
      return "10:00-10:50"
    when 3
      return "11:00-11:50"
    when 4
      return "12:00-12:50"
    when 5
      return "13:00-13:50"
    when 6
      return "14:00-14:50"
    when 7
      return "15:00-15:50"
    when 8
      return "16:00-16:50"
    when 9
      return "17:00-17:50"
    when 10
      return "18:00-18:50"
    when 11
      return "19:00-19:50"
    else
      return "-1"
    end
  end
  def format_class_type(type)
    case type
    when 0
      return "ЛЕ"
    when 1
      return "ЛА"
    when 2
      return "ЛК"
    when 3
      return "ПР"
    when 4
      return "КМ"
    else
      return "ЛЕ"
    end
  end

end

