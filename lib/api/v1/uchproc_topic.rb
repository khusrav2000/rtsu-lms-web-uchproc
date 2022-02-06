module Api::V1::UchprocTopic


  def subject_json(isu_tema,user,session,include)
    data={}
    data['isu_tema_id'] = isu_tema.isu_tblvdpstkr_id
    data['cnzap'] = isu_tema.cnzap.strip
    data['dtzap'] = Date.parse(isu_tema.dtzap.to_s)
    data['tema'] = isu_tema.ctema
    data['kol_lek'] = isu_tema.nkolch
    data['kol_sem'] = isu_tema.nkolchsem
    data['kol_prak'] = isu_tema.nkolchprak
    data['kol_lab'] = isu_tema.nkolchlab
    data['kol_kmd'] = isu_tema.nkolchkmdro
    data['kol_obsh'] = isu_tema.nkolchv
    data
  end
  def subjects_json(data,header,user,session,include)
    res={}
    res["header"] = header
    body =[]
    data.map do |isu_tema|
      body.push(subject_json(isu_tema,user,session,include))
    end
    res["body"] = body
    res
  end
end

