require 'atom'
class IsuTimetable < ActiveRecord::Base
  self.table_name = 'isu_tblrlstzkrst'
  self.primary_key = "isu_tblrlstzkrst_id"
  belongs_to :isu_timetable_grp, class_name: "IsuTimetableGrp", foreign_key:  "id_zkrst"
end
