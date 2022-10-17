class UchprocGroup < ActiveRecord::Base
  self.table_name = "isu_grp"
  self.primary_key = "isu_grp_id"
  belongs_to :uchproc_class

  def self.get_group_by_account_id(account_id)
    group_id = 0
    group_account = Account.find(account_id)
    if group_account
      group_id = group_account.sis_source_id.include?('grp_') ? group_account.sis_source_id[4 - group_account.sis_source_id.length..-1].to_i : 0
    end
    group = UchprocGroup.where(:isu_grp_id => group_id).first
    return group
  end
end

