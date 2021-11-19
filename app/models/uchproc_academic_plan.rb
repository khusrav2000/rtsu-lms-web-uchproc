class UchprocAcademicPlan < ActiveRecord::Base
  self.table_name='isu_upl'
  self.primary_key='isu_upl_id'

  has_many :uchproc_academic_plan_detail, :foreign_key => 'kuc'

  def self.season_study_weeks(academic_plan_id, class_number, count_lessons=[], course_id, user )
    @count_lessons = count_lessons
    errors = []
    academic_plan = UchprocAcademicPlanDetail.where(:kuc => academic_plan_id, :ckurs => class_number).first
    season = Course.find(course_id).enrollment_term.name
    unless academic_plan
      errors << "Academic plan not found!"
    end
    week_numbers = []
    weeks = (1..16)
    difference = 0
    if season.split('')[0].include?('Л')
      weeks = (23..38)
      difference = 22
    end
    if errors.length == 0
      week_plans = week_plans_to_array(academic_plan)
      weeks.each do |i|
        unless week_plans[i].include?('П')
          week_numbers << i - difference
        end
      end
    end

    if week_numbers.length == 10
      header = point_journal_header_json(week_numbers, 5, 20.0,
                                         [2.00, 0.00, 2.00, 3.00, 2.00, 6.00, 0.00, 10.00, 0.00, 0.00], course_id, user)
      rating_week_count = 5
    elsif week_numbers.length == 12
      header = point_journal_header_json(week_numbers, 6, 16.67,
                                         [2.00, 0.00, 3.00, 2.00, 2.00, 4.00, 0.00, 8.67, 0.00, 0.00], course_id, user)
      rating_week_count = 6
    elsif week_numbers.length == 16
      header = point_journal_header_json(week_numbers, 8, 12.5,
                                         [2.00, 0.00, 1.00, 1.00, 2.00, 3.50, 0.00, 6.00, 0.00, 0.00], course_id, user)
      rating_week_count = 8
    else
      errors << "Academic plan details are wrong!"
    end
    if errors.length > 0
      {
        errors: errors
      }
    else
      {
        rating_week_count: rating_week_count,
        header: header,
        week_numbers: week_numbers
      }
    end
  end

  def self.point_journal_header_json(week_numbers, rating_week_count, max_week_point, divided_points, course_id, user)
    header = {}
    header[:rating] = {
      first: [],
      second: []
    }
    journal_point_type = 'Dividing'
    if course_id.present?
      course = Course.find(course_id)
      if course.present? && course.journal_point_type
        journal_point_type = course.journal_point_type
      end
    end

    group = course.account
    root_account = group.root_account
    header[:max_week_point] = max_week_point
    header[:max_lecture_att] = divided_points[0]
    header[:max_practical_att] = divided_points[2]
    header[:max_practical_act] = divided_points[3]
    header[:max_KMDRO_att] = divided_points[4]
    header[:max_KMDRO_act] = divided_points[5]
    header[:max_KMD] = divided_points[7]
    header[:journal_point_type] = journal_point_type
    current_week_number = UchprocAcademicYear.current_week_number(course_id)

    (0..rating_week_count - 1).each do |i|
      header[:rating][:first] << {
        number: week_numbers[i],
        is_editable: user.can_access_week?(group, week_numbers[i], current_week_number == week_numbers[i]) || user.can_access_week?(course, week_numbers[i], current_week_number == week_numbers[i]),
        attendance_permission: self.search_count_lessons_by_week(week_numbers[i], course, root_account)
      }
    end
    (rating_week_count..rating_week_count * 2 - 1).each do |i|
      header[:rating][:second] << {
        number: week_numbers[i],
        is_editable: user.can_access_week?(group, week_numbers[i], current_week_number == week_numbers[i]) || user.can_access_week?(course, week_numbers[i], current_week_number == week_numbers[i]),
        attendance_permission: self.search_count_lessons_by_week(week_numbers[i], course, root_account)
      }
    end
    header
  end

  def self.week_plans_to_array(academic_plan)
    [
      academic_plan.ned00,
      academic_plan.ned01, academic_plan.ned02, academic_plan.ned03, academic_plan.ned04, academic_plan.ned05,
      academic_plan.ned06, academic_plan.ned07, academic_plan.ned08, academic_plan.ned09, academic_plan.ned10,
      academic_plan.ned11, academic_plan.ned12, academic_plan.ned13, academic_plan.ned14, academic_plan.ned15,
      academic_plan.ned16, academic_plan.ned17, academic_plan.ned18, academic_plan.ned19, academic_plan.ned20,
      academic_plan.ned21, academic_plan.ned22, academic_plan.ned23, academic_plan.ned24, academic_plan.ned25,
      academic_plan.ned26, academic_plan.ned27, academic_plan.ned28, academic_plan.ned29, academic_plan.ned30,
      academic_plan.ned31, academic_plan.ned32, academic_plan.ned33, academic_plan.ned34, academic_plan.ned35,
      academic_plan.ned36, academic_plan.ned37, academic_plan.ned38, academic_plan.ned39, academic_plan.ned40,
      academic_plan.ned41, academic_plan.ned42, academic_plan.ned43, academic_plan.ned44, academic_plan.ned45,
      academic_plan.ned46, academic_plan.ned47, academic_plan.ned48, academic_plan.ned49, academic_plan.ned50,
      academic_plan.ned51, academic_plan.ned52, academic_plan.ned53, academic_plan.ned54, academic_plan.ned55,
      academic_plan.ned56, academic_plan.ned57, academic_plan.ned58, academic_plan.ned59, academic_plan.ned60,
      academic_plan.ned61, academic_plan.ned62, academic_plan.ned63, academic_plan.ned64
    ]
  end
  def self.search_count_lessons_by_week(week_number, course, account)
    permission_type_lesson = {:lecture => false, :practical => false, :kmdro =>false}
    if (course.attendance_point_journal_relation.nil? && account.attendance_point_journal_relation?) || course.attendance_point_journal_relation
      @count_lessons.map do |count_lesson|
        if count_lesson.week_number == week_number
          permission_type_lesson[:lecture] = count_lesson.lecture > 0
          permission_type_lesson[:practical] = count_lesson.seminar > 0 || count_lesson.practical > 0
          permission_type_lesson[:kmdro] = count_lesson.laboratory > 0 || count_lesson.kmdro > 0
        end
      end
    else
      permission_type_lesson = {:lecture => true, :practical => true, :kmdro => true}
    end
    permission_type_lesson
  end
end

