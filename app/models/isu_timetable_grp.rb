require 'atom'
class IsuTimetableGrp < ActiveRecord::Base
  self.table_name = 'isu_tblrlstzkr'
  self.primary_key = "isu_tblrlstzkr_id"
  #has_many :isu_timetable
  belongs_to :isu_timetable_krs,  foreign_key:  "krs"
end
