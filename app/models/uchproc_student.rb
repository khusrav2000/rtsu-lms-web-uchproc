class UchprocStudent < ActiveRecord::Base
  self.table_name = "isu_std"
  self.primary_key = "isu_std_id"

  belongs_to :uchproc_class, :foreign_key => 'kkr'
  belongs_to :uchproc_group, class_name: "UchprocGroup", foreign_key:  "kgr"

  validates :nst, length: { minimum: 2 }
  validates :nstt, length: { minimum: 2 }
  validates :nkart, length: { minimum: 10 }
  validates :kzc, length: { minimum: 10 }
  validates :pol, length: { minimum: 1 }
  validates :fin, length: { minimum: 1 }
  validates :kfk, numericality: { only_integer: true, better_than: 0 }
  validates :ksp, numericality: { only_integer: true, better_than: 0 }
  validates :kkr, numericality: { only_integer: true, better_than: 0 }
  validates :kgr, numericality: { only_integer: true, better_than: 0 }
  validates :tel1, length: { minimum: 9 }

  before_create :infer_defaults
  before_save :infer_save

  def infer_defaults
    self.updatedby = 100
    self.createdby = 100
    self.ad_client_id = 1000000
    self.ad_org_id = 1000000
    self.chactive = "1"
  end
  def infer_save
    case self.fin
    when "Budget"
      self.fin = "Б"
    when "Contract"
      self.fin = "Д"
    when "Mixed"
      self.fin = "С"
    else
      self.fin = ""
    end

    case self.pol
    when "Male"
      self.pol = "м"
    when "Female"
      self.pol = "ж"
    else
      self.pol = ""
    end
  end

  def self.get_next_id
    UchprocStudent.select("isu_nextid('#{self.table_name}')").first.isu_nextid
  end

  def add_to_canvas(account=nil)
    std_sis = "std_#{self.isu_std_id}"
    name = self.nstt
    correct_name = Uchproc::UchprocHelper.convert_to_utf8(name.strip)
    sortable_name = correct_name.gsub(" ", ",")
    params = {user: {name: correct_name, short_name: correct_name, sortable_name: sortable_name},
              time_zone: "Asia/Tashkent", locale: "ru", terms_of_use: "0", skip_registration: "1",
              pseudonym: {unique_id: self.kzc.strip, password: self.nkart.strip, sis_user_id: std_sis,
                          integration_id: std_sis },communication_channel: {skip_confirmation: "1"}}
    user = Uchproc::UchprocUser.new(account).add_user(params)
    return user
  end
  def update_to_canvas(account=nil)
    std_sis = "std_#{self.isu_std_id}"
    name = self.nstt
    correct_name =  Uchproc::UchprocHelper.convert_to_utf8(name.strip)
    sortable_name = correct_name.gsub(" ", ",")
    enable_sis_reactivation = "0"
    if self.chactive.strip.to_i == 1
      enable_sis_reactivation = "1"
    end
    params = {user: {name: correct_name, short_name: correct_name, sortable_name: sortable_name},
              time_zone: "Asia/Tashkent", locale: "ru", terms_of_use: "0", skip_registration: "1",
              pseudonym: {unique_id: self.kzc.strip, password: self.nkart.strip, sis_user_id: std_sis,
                          integration_id: std_sis },communication_channel: {skip_confirmation: "1"}, enable_sis_reactivation: enable_sis_reactivation}
    user = Uchproc::UchprocUser.new(account).update_user(params)
    return user
  end
  def get_pseudonym(account)
    sis = "std_#{self.isu_std_id}"
    pseudonym = account.pseudonyms.where(:sis_user_id => sis).first
    return pseudonym
  end
  def get_group
    sis = "grp_#{self.kgr}"
    return  Account.where(sis_source_id: sis).first
  end

end

