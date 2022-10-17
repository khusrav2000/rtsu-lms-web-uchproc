class UchprocIsuTblvdkr < ActiveRecord::Base
  self.table_name = "isu_tblvdkr"
  self.primary_key = "isu_tblvdkr_id"

  belongs_to :uchproc_course, :foreign_key => "kpr"
  belongs_to :uchproc_user, :foreign_key => "kst"
  belongs_to  :uchproc_group, :foreign_key => "kgr"
end
