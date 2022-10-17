module Api::V1::UchprocStudentAttendance

  def attendance_json(isu_std_attendance,header,user,session,include)
    data={}
    data['cposes'] = [
      isu_std_attendance.cpos1,  isu_std_attendance.cpos2,  isu_std_attendance.cpos3,  isu_std_attendance.cpos4,
      isu_std_attendance.cpos5,  isu_std_attendance.cpos6,  isu_std_attendance.cpos7,  isu_std_attendance.cpos8,
      isu_std_attendance.cpos9,  isu_std_attendance.cpos10, isu_std_attendance.cpos11, isu_std_attendance.cpos12,
      isu_std_attendance.cpos13, isu_std_attendance.cpos14, isu_std_attendance.cpos15, isu_std_attendance.cpos16,
      isu_std_attendance.cpos17, isu_std_attendance.cpos18, isu_std_attendance.cpos19, isu_std_attendance.cpos20,
      isu_std_attendance.cpos21, isu_std_attendance.cpos22, isu_std_attendance.cpos23, isu_std_attendance.cpos24,
      isu_std_attendance.cpos25, isu_std_attendance.cpos26, isu_std_attendance.cpos27, isu_std_attendance.cpos28,
      isu_std_attendance.cpos29, isu_std_attendance.cpos30, isu_std_attendance.cpos31, isu_std_attendance.cpos32,
      isu_std_attendance.cpos33, isu_std_attendance.cpos34, isu_std_attendance.cpos35, isu_std_attendance.cpos36,
      isu_std_attendance.cpos37, isu_std_attendance.cpos38, isu_std_attendance.cpos39, isu_std_attendance.cpos40,
      isu_std_attendance.cpos41, isu_std_attendance.cpos42, isu_std_attendance.cpos43, isu_std_attendance.cpos44,
      isu_std_attendance.cpos45, isu_std_attendance.cpos46, isu_std_attendance.cpos47, isu_std_attendance.cpos48,
      isu_std_attendance.cpos49, isu_std_attendance.cpos50, isu_std_attendance.cpos51, isu_std_attendance.cpos52,
      isu_std_attendance.cpos53, isu_std_attendance.cpos54, isu_std_attendance.cpos55, isu_std_attendance.cpos56,
      isu_std_attendance.cpos57, isu_std_attendance.cpos58, isu_std_attendance.cpos59, isu_std_attendance.cpos60,
      isu_std_attendance.cpos61, isu_std_attendance.cpos62, isu_std_attendance.cpos63, isu_std_attendance.cpos64,
      isu_std_attendance.cpos65, isu_std_attendance.cpos66, isu_std_attendance.cpos67, isu_std_attendance.cpos68,
      isu_std_attendance.cpos69, isu_std_attendance.cpos70, isu_std_attendance.cpos71, isu_std_attendance.cpos72,
      isu_std_attendance.cpos73, isu_std_attendance.cpos74, isu_std_attendance.cpos75, isu_std_attendance.cpos76,
      isu_std_attendance.cpos77, isu_std_attendance.cpos78, isu_std_attendance.cpos79, isu_std_attendance.cpos80,
      isu_std_attendance.cpos81, isu_std_attendance.cpos82, isu_std_attendance.cpos83, isu_std_attendance.cpos84,
      isu_std_attendance.cpos85, isu_std_attendance.cpos86, isu_std_attendance.cpos87, isu_std_attendance.cpos88,
      isu_std_attendance.cpos89, isu_std_attendance.cpos90, isu_std_attendance.cpos91, isu_std_attendance.cpos92,
      isu_std_attendance.cpos93, isu_std_attendance.cpos94, isu_std_attendance.cpos95, isu_std_attendance.cpos96 ]

    data['cposes'] = data['cposes'][0..header.length-1].reverse
    data['nst'] = isu_std_attendance.nst
    data['isu_std_id'] = isu_std_attendance.isu_std_id
    data['isu_std_attendance_id'] = isu_std_attendance.isu_tblvdtstkr_id
    data['kzc'] = isu_std_attendance.kzc
    data
  end

  def attendancess_json(data,header,user,session,include)
    res={}
    res["header"] = header
    body =[]
    data.map do |std_attendance|
      body.push(attendance_json(std_attendance,header,user,session,include))
    end
    res["body"] = body
    res
  end
end

