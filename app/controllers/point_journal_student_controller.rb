class PointJournalStudentController < ApplicationController
  before_action :require_user
  def index
    if @current_user.can_access_any_account_journals?([:student_points]) || @current_user.can_access_any_course_journals?([:student_points])
      if sis = @current_user.pseudonym.sis_user_id
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
        @student_points = Array.new(courses.length) {Hash.new}
        i = -1
        courses.map do |course|
          teachers = course.teachers
          teachers_name = ""
          teachers.map do |teacher|
            teachers_name += teacher.name
          end
          if cext = course.course_ext
            kvd = cext.isu_tblvdkr_id
            points = UchprocPointJournal.where("kvd =? AND kst =?", kvd, std_id).first
            if points
              weeks_points = weeks_points(points)
              i = i + 1
              @student_points[i]['course_name'] = course.name
              @student_points[i]['teachers'] = teachers_name
              @student_points[i]['points'] = weeks_points
            end
          end
        end

      end
    else
      render "shared/unauthorized", status: :unauthorized, content_type: Mime::Type.lookup('text/html'), formats: :html
    end

  end

  def weeks_points(points)
    week_point = Array.new(20, 0)
    1.step(8, 1) do |i|
      column_name = "oceblkr#{i}"
      point = points[column_name]
      week_point[i] = point.to_s('2F')
    end
    week_point[9] = points.oceblkr8_i.to_s('2F')
    10.step(17, 1) do |i|
      column_name = "oceblkr#{i - 1}"
      point = points[column_name]
      week_point[i] = point.to_s('2F')
    end
    week_point[18] = points.oceblkr16_i.to_s('2F')
    week_point
  end
end

