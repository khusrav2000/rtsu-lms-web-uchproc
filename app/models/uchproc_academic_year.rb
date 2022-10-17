class UchprocAcademicYear < ActiveRecord::Base
  self.table_name = "isu_ugd"
  self.primary_key = "isu_ugd_id"

  def last_season_name
    season = UchprocAcademicYear.order(isu_ugd_id: :desc)
    season[0].ses + season[0].ucg
  end

  def self.last_academic_year
    season = UchprocAcademicYear.order(isu_ugd_id: :desc).first
    {
      name: season.ses + season.ucg,
      id: season.isu_ugd_id
    }
  end



  def self.start_season_date(season_id)
    UchprocAcademicYear.find(season_id).ducgn
  end

  def self.current_week_number(course_id)
    season_start_date = Course.find(course_id).enrollment_term.start_at
    now_date = DateTime.now
    week_number = 1
    while season_start_date + 1.week < now_date
      week_number += 1
      season_start_date = season_start_date + 1.week
    end
    week_number
  end

end

