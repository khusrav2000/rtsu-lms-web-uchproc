class UchprocUser < ActiveRecord::Base
  self.table_name = "isu_sot"
  self.primary_key = "isu_sot_id"

  has_many :uchproc_isu_tblvdkr
  has_one :uchproc_login, -> { where("isu_prl.kst<>0")},:foreign_key => "kst"
  def add_to_canvas(account=nil, prefix_sis='tch')
    user_sis = prefix_sis + "_#{self.isu_sot_id}"
    name = self.nstt
    correct_name = Uchproc::UchprocHelper.convert_to_utf8(name.strip)
    sortable_name = correct_name.gsub(" ", ",")
    uch_login = self.uchproc_login
    if uch_login
      pass = Uchproc::UchprocHelper.uchproc_decode_password(uch_login)
      if pass
        params = {user: {name: correct_name, short_name: correct_name, sortable_name: sortable_name},
                  time_zone: "Asia/Tashkent", locale: "ru", terms_of_use: "0", skip_registration: "1",
                  pseudonym: {unique_id: uch_login.clogin.strip!, password: pass.strip!, sis_user_id: user_sis,
                              integration_id: user_sis},communication_channel: {skip_confirmation: "1"}}
        @user = Uchproc::UchprocUser.new(account).add_user(params)
      end
    end
    return @user
  end
  def update_to_canvas(account=nil, prefix_sis='tch')
    user_sis = prefix_sis + "_#{self.isu_sot_id}"
    name = self.nstt
    correct_name = Uchproc::UchprocHelper.convert_to_utf8(name.strip)
    sortable_name = correct_name.gsub(" ", ",")
    uch_login = self.uchproc_login
    enable_sis_reactivation = "0"
    if self.isactive == 'Y'
      enable_sis_reactivation = "1"
    end
    if uch_login
      pass = Uchproc::UchprocHelper.uchproc_decode_password(uch_login)
      if pass
        params = {user: {name: correct_name, short_name: correct_name, sortable_name: sortable_name},
                  time_zone: "Asia/Tashkent", locale: "ru", terms_of_use: "0", skip_registration: "1",
                  pseudonym: {unique_id: uch_login.clogin.strip!, password: pass.strip!, sis_user_id: user_sis,
                              integration_id: user_sis},communication_channel: {skip_confirmation: "1"}, enable_sis_reactivation: enable_sis_reactivation}
        @user = Uchproc::UchprocUser.new(account).update_user(params)
      end
    end
    return @user
  end
end

