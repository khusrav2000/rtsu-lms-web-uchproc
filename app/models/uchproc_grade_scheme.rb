class UchprocGradeScheme < ActiveRecord::Base
  self.table_name = "isu_tblsysoce"
  self.primary_key = "isu_tblsysoce_id"

  def self.get_grades(point)
    point = point.to_i
    grade = UchprocGradeScheme.where("ocprmin <= #{point} AND #{point} <= ocprmax").first
    {
      :grade_word => grade.ocbuk,
      :grade_exact => grade.occif
    }
  end
end
