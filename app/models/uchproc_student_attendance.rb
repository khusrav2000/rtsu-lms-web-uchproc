require 'atom'

class UchprocStudentAttendance < ActiveRecord::Base
  self.table_name = 'isu_tblvdtstkr'
  self.primary_key = "isu_tblvdtstkr_id"
  belongs_to :uchproc_student, foreign_key: "kst"

end





