require 'atom'
class UchprocTopic < ActiveRecord::Base
  self.table_name = 'isu_tblvdpstkr'
  self.primary_key = "isu_tblvdpstkr_id"
  def self.get_count_lessons(kvd)
    UchprocTopic.select("sum(nkolch) as lecture, sum(nkolchsem) as seminar, sum(nkolchprak) as practical, sum(nkolchlab) as laboratory, sum(nkolchkmdro) as kmdro, adempiere.get_week_number('2021-01-25 00:00:00', dtzap) as week_number")
           .where(:kvd => kvd)
           .group(:week_number)
  end

  def self.get_next_id
    UchprocTopic.select("isu_nextid('#{self.table_name}')").first.isu_nextid
  end
end
