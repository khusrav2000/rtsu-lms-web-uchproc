module Api::V1::PointJournal

  def sub_accounts(parent_id, prefix)

    prefixs = {
      :fac => :faculties,
      :spe => :specialties,
      :krs => :kurses,
      :grp => :groups
    }
    child = {
      :fac => :spe,
      :spe => :krs,
      :krs => :grp,
      :grp => nil
    }
    headers = @uchproc_headers.select { |uchproc_header| uchproc_header.parent_account_id == parent_id }
    headers.map do |uchproc_header|
      code = uchproc_header.code
      code||= uchproc_header.name

      data = {
        :id => uchproc_header.id,
        :code => code,
      }
      if child[:"#{prefix}"]
        data[:"#{prefixs[:"#{child[:"#{prefix}"]}"]}"] = sub_accounts(uchproc_header.id, child[:"#{prefix}"])
      end
      data
    end
  end
  def point_journal_header_json(headers,user,session,include)
    @uchproc_headers = headers
    headers  = @uchproc_headers.select { |header| header.sis_source_id && header.sis_source_id.start_with?("fak_")}
    {:faculties => headers.map do |head_fac|
      if head_fac.sis_source_id && head_fac.sis_source_id.start_with?("fak_")
        {
          :id => head_fac.id,
          :code => head_fac.code,
          :specialties => sub_accounts(head_fac.id, "spe")
        }
      end
    end
    }
  end

  def point_journal_header_json_old(headers,user,session,include)
    data = {:faculties => []}
    @uchproc_headers = headers
    faculty = {}
    specialty = {}
    kurs = {}
    group = {}
    preheader = nil
    headers.each { |header|
      if preheader == nil
        faculty = {
          :id => header.isu_fak_id,
          :code => header.kfk,
          :name => header.fak_name,
          :specialties => []
        }

        specialty = {
          :id => header.isu_spe_id,
          :code => header.ksp,
          :name => header.spe_name,
          :kurses => []
        }

        kurs = {
          :id => header.isu_krs_id,
          :code => header.kkr,
          :groups => []
        }

        if header.code_group.length > 0
          group = {
            :id => header.isu_grp_id,
            :code => "#{header.kgr}(#{header.code_group})"
          }
        else
          group = {
            :id => header.isu_grp_id,
            :code => header.kgr
          }
        end


      else
        if header.kfk != preheader.kfk
          kurs[:groups] << group
          specialty[:kurses] << kurs
          faculty[:specialties] << specialty
          data[:faculties] << faculty

          faculty = {
            :id => header.isu_fak_id,
            :code => header.kfk,
            :name => header.fak_name,
            :specialties => []
          }

          specialty = {
            :id => header.isu_spe_id,
            :code => header.ksp,
            :name => header.spe_name,
            :kurses => []
          }

          kurs = {
            :id => header.isu_krs_id,
            :code => header.kkr,
            :groups => []
          }

          if header.code_group.length > 0
            group = {
              :id => header.isu_grp_id,
              :code => "#{header.kgr}(#{header.code_group})"
            }
          else
            group = {
              :id => header.isu_grp_id,
              :code => header.kgr
            }
          end
        elsif header.ksp != preheader.ksp
          kurs[:groups] << group
          specialty[:kurses] << kurs
          faculty[:specialties] << specialty
          specialty = {
            :id => header.isu_spe_id,
            :code => header.ksp,
            :name => header.spe_name,
            :kurses => []
          }

          kurs = {
            :id => header.isu_krs_id,
            :code => header.kkr,
            :groups => []
          }

          if header.code_group.length > 0
            group = {
              :id => header.isu_grp_id,
              :code => "#{header.kgr}(#{header.code_group})"
            }
          else
            group = {
              :id => header.isu_grp_id,
              :code => header.kgr
            }
          end
        elsif header.kkr != preheader.kkr
          kurs[:groups] << group
          specialty[:kurses] << kurs
          kurs = {
            :id => header.isu_krs_id,
            :code => header.kkr,
            :groups => []
          }

          if header.code_group.length > 0
            group = {
              :id => header.isu_grp_id,
              :code => "#{header.kgr}(#{header.code_group})"
            }
          else
            group = {
              :id => header.isu_grp_id,
              :code => header.kgr
            }
          end
        else
          kurs[:groups] << group
          if header.code_group.length > 0
            group = {
              :id => header.isu_grp_id,
              :code => "#{header.kgr}(#{header.code_group})"
            }
          else
            group = {
              :id => header.isu_grp_id,
              :code => header.kgr
            }
          end
        end
      end
      preheader = header
    }
    kurs[:groups] << group
    specialty[:kurses] << kurs
    faculty[:specialties] << specialty
    data[:faculties] << faculty

    data
  end

  def week_point_divide_json(point)
    if point.strip == ""
      point = "0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00 0.00"
    end
    points = point.split
    divided = {}
    divided[:lecture_att] = points[0]
    divided[:practical_att] = points[2]
    divided[:practical_act] = points[3]
    divided[:KMDRO_att] = points[4]
    divided[:KMDRO_act] = points[5]
    divided[:KMD] = points[7]
    divided
  end

  def student_points_journal_json(student_points, rating_week_count, week_numbers)
    points = {}
    points[:kvd] = student_points.kvd
    points[:full_name] = student_points.nst.strip
    points[:student_id] = student_points.isu_std_id
    points[:record_book] = student_points.kzc.strip
    #Chenge for DDK
    points[:absence_threshold] = false #student_points.itjurkrss > 48
    points[:rating] = {
      first: {
        weeks: [],
        total: student_points.oceblkr8_i
      },
      second: {
        weeks: [],
        total: student_points.oceblkr16_i
      }
    }
    week_points_array = week_points_to_array_json(student_points)
    (0..rating_week_count - 1).each do |i|
      points[:rating][:first][:weeks] << week_points_array[week_numbers[i] - 1]
    end
    (rating_week_count..rating_week_count * 2 - 1).each do |i|
      points[:rating][:second][:weeks] << week_points_array[week_numbers[i] - 1]
    end

    points[:total_point] = student_points.itoceblkr
    points[:assessment_word] = student_points.itocekr
    points[:assessment] = student_points.oce
    points[:assessment_exact] = student_points.itocebl
    points[:exam] = student_points.oceblkr
    points[:exam_fx] = student_points.oceblkr27
    points[:exam_f] = student_points.oceblkr19
    points
  end

  def week_points_to_array_json(student_points)
    [
      { point: student_points.oceblkr1,  divided: week_point_divide_json(student_points.mcocer1),  week_number: 1 },
      { point: student_points.oceblkr2,  divided: week_point_divide_json(student_points.mcocer2),  week_number: 2 },
      { point: student_points.oceblkr3,  divided: week_point_divide_json(student_points.mcocer3),  week_number: 3 },
      { point: student_points.oceblkr4,  divided: week_point_divide_json(student_points.mcocer4),  week_number: 4 },
      { point: student_points.oceblkr5,  divided: week_point_divide_json(student_points.mcocer5),  week_number: 5 },
      { point: student_points.oceblkr6,  divided: week_point_divide_json(student_points.mcocer6),  week_number: 6 },
      { point: student_points.oceblkr7,  divided: week_point_divide_json(student_points.mcocer7),  week_number: 7 },
      { point: student_points.oceblkr8,  divided: week_point_divide_json(student_points.mcocer8),  week_number: 8 },
      { point: student_points.oceblkr9,  divided: week_point_divide_json(student_points.mcocer9),  week_number: 9 },
      { point: student_points.oceblkr10, divided: week_point_divide_json(student_points.mcocer10), week_number: 10},
      { point: student_points.oceblkr11, divided: week_point_divide_json(student_points.mcocer11), week_number: 11},
      { point: student_points.oceblkr12, divided: week_point_divide_json(student_points.mcocer12), week_number: 12},
      { point: student_points.oceblkr13, divided: week_point_divide_json(student_points.mcocer13), week_number: 13},
      { point: student_points.oceblkr14, divided: week_point_divide_json(student_points.mcocer14), week_number: 14},
      { point: student_points.oceblkr15, divided: week_point_divide_json(student_points.mcocer15), week_number: 15},
      { point: student_points.oceblkr16, divided: week_point_divide_json(student_points.mcocer16), week_number: 16}
    ]
  end

  def students_points_journal_json(students_points, study_weeks, user, session, include)
    points = students_points.map{|student_points| student_points_journal_json(student_points,
                                                                              study_weeks[:rating_week_count],
                                                                              study_weeks[:week_numbers])}
    {header: study_weeks[:header], points: points}
  end

end

