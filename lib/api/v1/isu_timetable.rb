module Api::V1::IsuTimetable

  def isu_courses_data_json(item,user,session,include)
    data={}
    data['teachers'] = item[:teachers]
    data['course_name'] = item[:course_name]
    data['course_id'] = item[:course_id]
    data['credit_number'] = item[:kolkr]
    data['in_timetable'] = item[:count]
    data
  end

  def isu_timetable_data_json(item,user,session,include)
    data={}
    data['course_id'] = item.id
    data['teachers'] = get_teachers(item)
    data['course_name'] = item.name
    data['week_day']  = item.cday
    data['classroom_number'] = item.cmesto
    data['time'] = convert_time_to_int(item.ctime)
    data['class_type'] = format_class_type_to_number(item.cvidzn)
    data['timetable_id'] = item.timetable_id
    data
  end

  def isu_timetable_json(courses, timetable, user, session, include)
    data = {}
    data["courses"] = []
    data["timetable"] = []
    day1 =[]
    day2 =[]
    day3 =[]
    day4 =[]
    day5 =[]
    day6 =[]
    day7 =[]
    @courses = courses
    @courses.map do |item|
      data["courses"] << isu_courses_data_json(item,user,session,include)
    end
    timetable.map do |item|
      if item.cday == '01' || item.cday == 1
        day1 << isu_timetable_data_json(item,user,session,include)
      elsif item.cday == '02' || item.cday == 2
        day2 << isu_timetable_data_json(item,user,session,include)
      elsif item.cday == '03' || item.cday == 3
        day3 << isu_timetable_data_json(item,user,session,include)
      elsif item.cday == '04' || item.cday == 4
        day4 << isu_timetable_data_json(item,user,session,include)
      elsif item.cday == '05' || item.cday == 5
        day5 << isu_timetable_data_json(item,user,session,include)
      elsif item.cday == '06' || item.cday == 6
        day6 << isu_timetable_data_json(item,user,session,include)
      elsif item.cday == '07' || item.cday == 7
        day7 << isu_timetable_data_json(item,user,session,include)
      end
    end
    data["timetable"] << day1
    data["timetable"] << day2
    data["timetable"] << day3
    data["timetable"] << day4
    data["timetable"] << day5
    data["timetable"] << day6
    data["timetable"] << day7
    data
  end

  def convert_time_to_int(time)
    case time
      when "08:00-08:50"
        return 1
      when "09:00-09:50"
        return 2
      when "10:00-10:50"
        return 3
      when "11:00-11:50"
        return 4
      when "12:00-12:50"
        return 5
      when "13:00-13:50"
        return 6
      when "14:00-14:50"
        return 7
      when "15:00-15:50"
        return 8
      when "16:00-16:50"
        return 9
      when "17:00-17:50"
        return 10
      when "18:00-18:50"
        return 11
      when "19:00-19:50"
        return 12
      else
        return 13
    end
  end

  def format_class_type_to_number(type)
    case type
    when "ЛЕ"
      return 0
    when "ЛА"
      return 1
    when "ЛК"
      return 2
    when "ПР"
      return 3
    when "КМ"
      return 4
    else
      return 0
    end
  end

  def get_teachers(course)
    sort_teachers = []
    temp_teachers = []
    @courses.map do |item|
      if item[:course_id] === course.id
        teachers = item[:teachers]
        teachers.map do |teacher|
          if teacher[:sot_id] == course.sot_id
            sort_teachers << {:teacher_id => teacher[:teacher_id], :teacher_name => teacher[:teacher_name]}
          else
            temp_teachers << {:teacher_id => teacher[:teacher_id], :teacher_name => teacher[:teacher_name]}
          end
        end
      end
    end
    temp_teachers.map do |temp_teacher|
      sort_teachers << temp_teacher
    end
    sort_teachers
  end
end
