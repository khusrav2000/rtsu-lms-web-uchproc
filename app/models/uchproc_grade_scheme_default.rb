class UchprocGradeSchemeDefault < ActiveRecord::Base
  self.table_name = "isu_tbltoce"
  self.primary_key = "isu_tbltoce_id"

  def self.get_grade(point)
    if point == 100
      point = point - 1
    end
    grade = UchprocGradeSchemeDefault.where("ocprmin <= #{point} AND #{point} < ocprmax").first
    grade.ocbuk
  end
end

