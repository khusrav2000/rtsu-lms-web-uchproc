class UchprocAcademicPlanDetail < ActiveRecord::Base
  self.table_name = 'isu_up1'
  self.primary_key = 'isu_up1_id'
  belongs_to :uchproc_academic_plan
end

