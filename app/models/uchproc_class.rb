class UchprocClass < ActiveRecord::Base
  self.table_name = "isu_krs"
  self.primary_key = "isu_krs_id"
  belongs_to :uchproc_specialty
  has_many :uchproc_group, :foreign_key => "kkr"

  def get_format_course
    format = 'on_campus'
    if self.kkr[0] == 'Ф' || self.kkr[0] == 'ф'
      format = 'online'
    elsif self.kkr[0] == 'З' || self.kkr[0] == 'з'
    format = 'blended'
    end
    format
  end
end

