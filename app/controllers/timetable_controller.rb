#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class TimetableController < ApplicationController
  before_action :require_user

  def index
    @subjects = [{"group_id":"2055","course_name":"Русский язык","teacher_name":"Кулобиев Абдулло Нишонович","isu_kvd":1086,"kolkr":3,"start_date":"2020-04-04T06:00:00Z"},{"group_id":"2055","course_name":"Информационные технологии","teacher_name":"Идиев Ғуфрон Аҳмадович","isu_kvd":1091,"kolkr":3,"start_date":"2020-04-04T06:00:00Z"},{"group_id":"2055","course_name":"Право","teacher_name":"Азизов Сорбон Азизович","isu_kvd":1336,"kolkr":3,"start_date":"2020-04-04T06:00:00Z"},{"group_id":"2055","course_name":"Этика и эстетика","teacher_name":"Мирзоева Азалбегим Мирзоевна","isu_kvd":1337,"kolkr":3,"start_date":"2020-04-04T06:00:00Z"},{"group_id":"2055","course_name":"Педагогика","teacher_name":"Наимов Зариф Ҷомиевич","isu_kvd":1338,"kolkr":4,"start_date":"2020-04-04T06:00:00Z"},{"group_id":"2055","course_name":"Математический анализ","teacher_name":"Холиқова Мастона Бобоназаровна","isu_kvd":1339,"kolkr":4,"start_date":"2020-04-04T06:00:00Z"},{"group_id":"2055","course_name":"Алгебра и теория чисел","teacher_name":"Чариев Умидилло","isu_kvd":1340,"kolkr":3,"start_date":"2020-04-04T06:00:00Z"},{"group_id":"2055","course_name":"Иностранный язык (английский)","teacher_name":"Мансурова Ҳабиба Ҳатамовна","isu_kvd":1348,"kolkr":4,"start_date":"2020-04-04T06:00:00Z"},{"group_id":"2055","course_name":"Геометрия","teacher_name":"Замонов Маликасрор Замонович","isu_kvd":1350,"kolkr":3,"start_date":"2020-04-04T06:00:00Z"},{"group_id":"2055","course_name":"Физическая культураа","teacher_name":"Намозов Тошқул Буриевич","isu_kvd":3140,"kolkr":2,"start_date":"2020-04-04T06:00:00Z"}]
    @data = main_filter_data
    logger.info "Data is #{{:data=>@data}}"
  end
  def main_filter_data
    data = nil
    roles = {
      :admin => 'AccountAdmin',
      :teacher => 'TeacherEnrollment'
    }
    role = Role.get_built_in_role(roles[:admin])
    account_fak_ids = [0]
    account_spe_ids = [0]
    account_krs_ids = [0]
    account_grp_ids = [0]
    all_accounts = false

    admin_accounts = @current_user.account_users.active.where(:role_id => role.id)
    admin_accounts.map do |admin_account|
      account = admin_account.account
      if account
        unless account.parent_account_id
          all_accounts = true
          break admin_account
        end
        if account.sis_source_id
          if account.sis_source_id.start_with?("fak_")
            account_fak_ids << account.id
          elsif account.sis_source_id.start_with?("spe_")
            account_spe_ids << account.id
          elsif account.sis_source_id.start_with?("krs_")
            account_krs_ids << account.id
          elsif account.sis_source_id.start_with?("grp_")
            account_grp_ids << account.id
          end
        end
      end
    end
    if all_accounts
      data = Account.active
                    .joins("INNER JOIN account_exts as fak_ext ON accounts.id = fak_ext.account_id
                  INNER JOIN accounts AS spe ON accounts.id = spe.parent_account_id
                  INNER JOIN account_exts as spe_ext ON spe.id = spe_ext.account_id
                  INNER JOIN accounts AS krs ON spe.id = krs.parent_account_id
                  INNER JOIN accounts AS grp ON krs.id = grp.parent_account_id")
                    .where("accounts.sis_source_id LIKE 'fak_%' AND spe.sis_source_id LIKE 'spe_%'
                  AND krs.sis_source_id LIKE 'krs_%' AND grp.sis_source_id LIKE 'grp_%' AND
                  spe.workflow_state<>'deleted' AND krs.workflow_state<>'deleted' AND grp.workflow_state<>'deleted'")
                    .select("accounts.id as isu_fak_id, fak_ext.code as kfk, spe.id as isu_spe_id, spe_ext.code as ksp,
                  krs.id as isu_krs_id, krs.name as kkr, grp.id as isu_grp_id, grp.name as kgr")
                    .order("kfk, ksp, kkr, kgr")
    else
      current_terms = @domain_root_account.
        enrollment_terms.
        active.
        where("(start_at<=? OR start_at IS NULL) AND (end_at >=? OR end_at IS NULL) AND NOT (start_at IS NULL AND end_at IS NULL)", Time.now.utc, Time.now.utc).
        limit(2).
        to_a
      current_term = current_terms.length == 1 ? current_terms.first : nil
      if current_term
        ids = [@current_user.id]
        courses = Course.active.by_teachers(ids).for_term(current_term)
        courses.map do |course|
          account_grp_ids << course.account_id
        end
      end
      data = Account.active
                    .joins("INNER JOIN account_exts as fak_ext ON accounts.id = fak_ext.account_id
                  INNER JOIN accounts AS spe ON accounts.id = spe.parent_account_id
                  INNER JOIN account_exts as spe_ext ON spe.id = spe_ext.account_id
                  INNER JOIN accounts AS krs ON spe.id = krs.parent_account_id
                  INNER JOIN accounts AS grp ON krs.id = grp.parent_account_id")
                    .where("accounts.sis_source_id LIKE 'fak_%' AND spe.sis_source_id LIKE 'spe_%'
                  AND krs.sis_source_id LIKE 'krs_%' AND grp.sis_source_id LIKE 'grp_%' AND
                  spe.workflow_state<>'deleted' AND krs.workflow_state<>'deleted' AND grp.workflow_state<>'deleted'
                  AND (accounts.id IN (?) OR spe.id IN (?) OR krs.id IN (?) OR grp.id IN (?))", account_fak_ids, account_spe_ids, account_krs_ids, account_grp_ids)
                    .select("accounts.id as isu_fak_id, fak_ext.code as kfk, spe.id as isu_spe_id, spe_ext.code as ksp,
                  krs.id as isu_krs_id, krs.name as kkr, grp.id as isu_grp_id, grp.name as kgr")
                    .order("kfk, ksp, kkr, kgr")
    end
    data
  end
end

