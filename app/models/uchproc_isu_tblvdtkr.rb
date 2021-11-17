class UchprocIsuTblvdtkr < ActiveRecord::Base
  self.table_name = "isu_tblvdtkr"
  self.primary_key = "isu_tblvdtkr_id"

  belongs_to :uchproc_course, :foreign_key => "kpr"
  belongs_to :uchproc_user, :foreign_key => "kst"
end
