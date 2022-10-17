module Api::V1::UchprocGroup

  def group_json(isu_grp, user, session, include)
    m={}
    m['isu_grp_id'] = isu_grp.isu_grp_id
    m['kgr'] = isu_grp.kgr
    m['kkr'] = isu_grp.kkr
    m
  end
  def groups_json(isu_grps, user, session, include)
    isu_grps.map{|isu_grp| isu_grp_json(isu_grp,user,session,include)}
  end
end

