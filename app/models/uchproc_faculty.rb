require 'atom'

class UchprocFaculty < ActiveRecord::Base
  self.table_name = 'isu_fak'
  self.primary_key = "isu_fak_id"
end

