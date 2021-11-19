module Api::V1::UchprocCourse

  def course_json(course)
    cour={}
    cour['group_id'] = course.kgr
    cour['course_name'] = course.npr
    cour['teacher_name'] = course.nst
    cour['isu_kvd'] = course.isu_tblvdkr_id
    cour['kolkr'] = course.kolkr
    cour['start_date'] = @academic_year_start_date
    cour
  end
  def course_json_new(course)
    cour={}
    cour['group_id'] = course[:group_id]
    cour['course_name'] = course[:course_name]
    cour['teacher_name'] = course[:teacher_name]
    cour['isu_kvd'] = course[:course_id]
    cour['kolkr'] = course[:kolkr]
    cour['start_date'] = @academic_year_start_date
    cour
  end

  def courses_json(courses, aca_start_date)
    @academic_year_start_date = aca_start_date.strftime("%d.%m.%Y")
    courses.map{|course| course_json_new(course)}
  end
end

