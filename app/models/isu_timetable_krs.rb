require 'atom'
class IsuTimetableKrs < ActiveRecord::Base
  self.table_name = 'isu_tblrlzgzkr'
  self.primary_key = "isu_tblrlzgzkr_id"
  has_many :isu_timetable_grp

end
