class UchprocMainFilterApiController < ApplicationController
  before_action :require_user
  include Uchproc::Apis::RequestHelper

  def show
    token = @current_user.pseudonyms.first.uchproc_token
    main_filter = get_main_filter(token)
    puts main_filter
    puts main_filter[:error]
  
    if main_filter[:error]
      if main_filter[:logout]
        logout_current_user
        flash[:logged_out] = true
        redirect_to login_url
        return
      end
      render :json => {:error => main_filter[:error]}
      return
    end

    render :json => main_filter[:payload]
  end

  # OLD version
  #def main_filter
  #  roles = {
  #    :admin => 'AccountAdmin',
  #    :advisor => 'AccountAdvisor',
  #    :teacher => 'TeacherEnrollment'
  #  }
  #  role_admin = Role.get_built_in_role('AccountAdmin', root_account_id: @domain_root_account.id)
  #  role_advisor = Role.where("name = ? AND workflow_state = ? AND root_account_id = ?", roles[:advisor], 'active', @domain_root_account.id).first
  #  account_fak_ids = [0]
  #  account_spe_ids = [0]
  #  account_krs_ids = [0]
  #  account_grp_ids = [0]
  #  all_accounts = false
  #  admin_accounts = @current_user.account_users.active.where(:role_id => role_admin.id)
  #  advisor_accounts = nil
  #   if role_advisor
  #     advisor_accounts = @current_user.account_users.active.where(:role_id => role_advisor.id)
  #   end
  #   if advisor_accounts && advisor_accounts.length > 0
  #     admin_accounts += advisor_accounts
  #     admin_accounts.flatten!
  #   end
  #   admin_accounts.map do |admin_account|
  #     account = admin_account.account
  #     if account
  #       unless account.parent_account_id
  #         all_accounts = true
  #         break admin_account
  #       end
  #       if account.sis_source_id
  #         if account.sis_source_id.start_with?("fak_")
  #           account_fak_ids << account.id
  #         elsif account.sis_source_id.start_with?("spe_")
  #           account_spe_ids << account.id
  #         elsif account.sis_source_id.start_with?("krs_")
  #           account_krs_ids << account.id
  #         elsif account.sis_source_id.start_with?("grp_")
  #           account_grp_ids << account.id
  #         end
  #       end
  #     end
  #   end
  #   if all_accounts
  #     data = Account.active
  #                   .joins("INNER JOIN account_exts as fak_ext ON accounts.id = fak_ext.account_id
  #                 INNER JOIN accounts AS spe ON accounts.id = spe.parent_account_id
  #                 INNER JOIN account_exts as spe_ext ON spe.id = spe_ext.account_id
  #                 INNER JOIN accounts AS krs ON spe.id = krs.parent_account_id
  #                 INNER JOIN accounts AS grp ON krs.id = grp.parent_account_id
  #                 INNER JOIN isu_grp  ON 'grp_'||isu_grp.kdn = grp.sis_source_id"
  #                   )
  #                   .where("accounts.sis_source_id LIKE 'fak_%' AND spe.sis_source_id LIKE 'spe_%'
  #                 AND krs.sis_source_id LIKE 'krs_%' AND grp.sis_source_id LIKE 'grp_%' AND
  #                 spe.workflow_state<>'deleted' AND krs.workflow_state<>'deleted' AND grp.workflow_state<>'deleted'")
  #                   .select("accounts.id as isu_fak_id, fak_ext.code as kfk, accounts.name as fak_name, spe.id as isu_spe_id, spe_ext.code as ksp,
  #                 spe.name as spe_name, krs.id as isu_krs_id, krs.name as kkr, grp.id as isu_grp_id, grp.name as kgr, rtrim(shgrp) as code_group")
  #                   .order("kfk, ksp, kkr, kgr")
  #   else
  #     current_terms = @domain_root_account.
  #       enrollment_terms.
  #       active.
  #       where("(start_at<=? OR start_at IS NULL) AND (end_at >=? OR end_at IS NULL) AND NOT (start_at IS NULL AND end_at IS NULL)", Time.now.utc, Time.now.utc).
  #       limit(2).
  #       to_a
  #     current_term = current_terms.length == 1 ? current_terms.first : nil
  #     if current_term
  #       ids = [@current_user.id]
  #       courses = Course.active.by_teachers_or_assistants(ids).for_term(current_term)
  #       courses.map do |course|
  #         account_grp_ids << course.account_id
  #       end
  #     end
  #     data = Account.active
  #                   .joins("INNER JOIN account_exts as fak_ext ON accounts.id = fak_ext.account_id
  #                 INNER JOIN accounts AS spe ON accounts.id = spe.parent_account_id
  #                 INNER JOIN account_exts as spe_ext ON spe.id = spe_ext.account_id
  #                 INNER JOIN accounts AS krs ON spe.id = krs.parent_account_id
  #                 INNER JOIN accounts AS grp ON krs.id = grp.parent_account_id
  #                 INNER JOIN isu_grp  ON 'grp_'||isu_grp.kdn = grp.sis_source_id")
  #                   .where("accounts.sis_source_id LIKE 'fak_%' AND spe.sis_source_id LIKE 'spe_%'
  #                 AND krs.sis_source_id LIKE 'krs_%' AND grp.sis_source_id LIKE 'grp_%' AND
  #                 spe.workflow_state<>'deleted' AND krs.workflow_state<>'deleted' AND grp.workflow_state<>'deleted'
  #                 AND (accounts.id IN (?) OR spe.id IN (?) OR krs.id IN (?) OR grp.id IN (?))", account_fak_ids, account_spe_ids, account_krs_ids, account_grp_ids )
  #                   .select("accounts.id as isu_fak_id, fak_ext.code as kfk, accounts.name as fak_name, spe.id as isu_spe_id, spe_ext.code as ksp,
  #                 spe.name as spe_name, krs.id as isu_krs_id, krs.name as kkr, grp.id as isu_grp_id, grp.name as kgr, rtrim(shgrp) as code_group")
  #                   .order("kfk, ksp, kkr, kgr")
  #   end
  #   render :json => point_journal_header_json_old(data, @current_user, @sessions, [])
  # end
end