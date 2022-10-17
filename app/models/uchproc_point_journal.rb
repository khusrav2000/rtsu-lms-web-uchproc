class UchprocPointJournal < ActiveRecord::Base
  self.table_name = "isu_tblvdstkr"
  self.primary_key = "isu_tblvdstkr_id"
  belongs_to :uchproc_student, :foreign_key => "kst"

  def self.recount_results_and_assessment(student_points, season_study_weeks, course_id, current_week_number)
    now_rating = 'FIRST_RATING'
    first_rating_point = 0.0
    second_rating_point = 0.0
    percent_assessment = 0.0
    first_rating_past_week_point = 0.0
    first_rating_past_week_count = 0
    second_rating_past_week_point = 0.0
    second_rating_past_week_count = 0
    header = season_study_weeks[:header]
    max_week_point = header[:max_week_point]
    header[:rating][:first].map do |week|
      first_rating_point += student_points[:"oceblkr#{week[:number]}"].to_f
      if week[:number] <= current_week_number
        first_rating_past_week_point += student_points[:"oceblkr#{week[:number]}"].to_f
        first_rating_past_week_count += 1
      end
    end
    header[:rating][:second].map do |week|
      second_rating_point += student_points[:"oceblkr#{week[:number]}"].to_f
      if current_week_number >= week[:number]
        now_rating = 'SECOND_RATING'
      end
      if week[:number] <= current_week_number
        second_rating_past_week_point += student_points[:"oceblkr#{week[:number]}"].to_f
        second_rating_past_week_count += 1
      end
    end
    if now_rating == 'FIRST_RATING'
      total_point = first_rating_point
      percent_assessment = (100 * first_rating_past_week_point) / (max_week_point * first_rating_past_week_count)
    else
      total_point = (first_rating_point + second_rating_point) / 2
      percent_assessment = ((100 * first_rating_past_week_point) / (max_week_point * first_rating_past_week_count) +
        (100 * second_rating_past_week_point) / (max_week_point * second_rating_past_week_count)) / 2
    end

    if current_week_number > 16
      percent_assessment = (percent_assessment + [student_points.oceblkr, student_points.oceblkr19, student_points.oceblkr27].max) / 2
      total_point = percent_assessment
    end
    grades = UchprocGradeScheme.get_grades(percent_assessment)
    grade_default = UchprocGradeSchemeDefault.get_grade(percent_assessment)

    student_points.update({
                            oceblkr8_i: float_point_to_string(first_rating_point),
                            oceblkr16_i: float_point_to_string(second_rating_point),
                            itoceblkr: float_point_to_string(total_point),
                            itocekr: grades[:grade_word],
                            itocebl: grades[:grade_exact],
                            oce: grade_default
                          })
  end

  def back_recount_results_and_assessment(student_points, season_study_weeks, course_id, current_week_number)
    UchprocPointJournal.recount_results_and_assessment(student_points, season_study_weeks, course_id, current_week_number)
  end

  def self.course_student_points(kvd, student_id)
    select_columns = "isu_tblvdstkr.*, isu_std.isu_std_id, isu_std.nst, isu_std.kzc, isu_std.ksp, isu_krs.kkr, isu_krs.kuc, 0 as itjurkrss"
    points = UchprocPointJournal.select(select_columns)
                                .joins(uchproc_student: :uchproc_class)
                                .where("isu_tblvdstkr.kvd = ? AND isu_std.isu_std_id = ?", kvd, student_id)
    specialty_id = points.first.ksp
    class_number = points.first.kkr.split('')[1]

    {
      academic_plan_id:  points.first.kuc,
      specialty_id: specialty_id,
      class_number: class_number,
      points: points.first
    }
  end

  def self.course_students_points(kvd, att_kvd, locale)
    @locale = locale
    select_columns = "isu_tblvdstkr.*, isu_std.isu_std_id, isu_std.nst, isu_std.kzc, isu_std.ksp, isu_krs.kkr, isu_krs.kuc, isu_tblvdtstkr.itjurkrss"
    if @locale == "tj"
      select_columns = "isu_tblvdstkr.*, isu_std.isu_std_id, isu_std.nstt as nst, isu_std.kzc, isu_std.ksp, isu_krs.kkr, isu_krs.kuc, isu_tblvdtstkr.itjurkrss"
    end
    points = UchprocPointJournal.select(select_columns)
                                .joins(uchproc_student: :uchproc_class)
                                .joins("INNER JOIN isu_tblvdtstkr ON isu_tblvdtstkr.kst = isu_std.isu_std_id")
                                .where("isu_tblvdstkr.kvd = ? AND isu_tblvdtstkr.kvd = ?", kvd, att_kvd)
                                .order(:nst)
    if @locale == "tj"
      points.map do |point|
        point.nst = convert_to_utf8(point.nst.strip)
      end
    end
    specialty_id = points.first.ksp
    class_number = points.first.kkr.split('')[1]
    {
      academic_plan_id:  points.first.kuc,
      specialty_id: specialty_id,
      class_number: class_number,
      points: points
    }
  end

  def self.course_academic_plan_class(course_id)
    academic_plan_and_class = UchprocPointJournal.select('isu_krs.kuc, isu_krs.kkr')
                                                 .joins(uchproc_student: :uchproc_class)
                                                 .where(kvd: course_id)
                                                 .order(:nst)
                                                 .first
    unless academic_plan_and_class
      return nil
    end

    {
      academic_plan_id: academic_plan_and_class.kuc,
      class_number: academic_plan_and_class.kkr.split('')[1]
    }
  end
  def self.course_specialty_class(course_id)
    specialty_and_class = UchprocPointJournal.select('isu_std.ksp, isu_krs.kkr')
                                             .joins(uchproc_student: :uchproc_class)
                                             .where(kvd: course_id)
                                             .order(:nst)
                                             .first

    {
      specialty_id: specialty_and_class.ksp,
      class_number: specialty_and_class.kkr.split('')[1]
    }
  end

  def self.correct_student_week_point?(season_study_weeks, point, divided_points, journal_point_type)
    header = season_study_weeks[:header]
    max_point_divided = [
      header[:max_lecture_att].to_f, 0.0, header[:max_practical_att].to_f, header[:max_practical_act].to_f,
      header[:max_KMDRO_att].to_f, header[:max_KMDRO_act].to_f, 0.0, header[:max_KMD].to_f, 0.0, 0.0
    ]
    week_point = 0.0
    is_correct = true
    (0..9).each do |i|
      week_point += divided_points[i]
      unless divided_points[i] <= max_point_divided[i]
        is_correct = false
      end
    end
    if (journal_point_type == 'Dividing' && week_point != point) || point > header[:max_week_point].to_f
      is_correct = false
    end
    is_correct
  end

  def self.float_point_to_string(point)
    str_point = point.to_s
    if str_point.split('.')[1].length < 2
      str_point += '0'
    end
    str_point
  end
  def float_point_to_string(point)
    str_point = point.to_s
    if str_point.split('.')[1].length < 2
      str_point += '0'
    end
    str_point
  end
  def self.convert_to_utf8(str)
    str = str.gsub("R", "Қ")
    str = str.gsub("r", "қ")
    str = str.gsub("B", "Ӣ")
    str = str.gsub("b", "ӣ")
    str = str.gsub("X", "Ҷ")
    str = str.gsub("x", "ҷ")
    str = str.gsub("[", "Ҳ")
    str = str.gsub("{", "ҳ")
    str = str.gsub("E", "Ӯ")
    str = str.gsub("e", "ӯ")
    str = str.gsub("U", "Ғ")
    str = str.gsub("u", "ғ")

    str
  end
end

