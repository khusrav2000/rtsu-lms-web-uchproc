#
# Copyright (C) 2020 - present Istiqlolsoft, Inc.
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


class UchprocGroupApiController < ApplicationController
  before_action :require_user
  before_action :get_context

  include Api::V1::UchprocGroup
  include Api::V1::UchprocCourse

  def create
  end


  def destroy
  end

  # @API List account admins
  #
  # A paginated list of the admins in the account
  #
  # @argument user_id[] [[Integer]]
  #   Scope the results to those with user IDs equal to any of the IDs specified here.
  #
  # @returns [IsuGrp]
  def index
    groups = UchprocGroup.all
    render :json => groups_json(groups,@current_user,@sessions,[])
  end

  def show
    isu_grp_id = params[:isu_grp_id]
    group = UchprocGroup.find(isu_grp_id)
    render :json => group_json(group,@current_user,@sessions,[])
  end

  def courses
    group_id = params[:ugroup_id]
    courses = UchprocTblvdkr.select('isu_tblvdkr.isu_tblvdkr_id,isu_tblvdkr.kgr, isu_prk.npr, isu_sot.nst, isu_tblvdkr.kolkr')
                               .joins(:uchproc_course)
                               .joins(:uchproc_user)
                               .where('kgr = ?', group_id)


    render :json => courses_json(courses, "")
  end


  def courses_current_period
    @locale = @current_user.locale
    @locale ||= @domain_root_account.default_locale
    if @locale == "en"
      @locale = @domain_root_account.default_locale
    end
    select_columns ="courses.id, isu_prk.npr as name, course_exts.kolkr"
    if @locale == "tj"
      select_columns ="courses.id, isu_prk.nprt as name, course_exts.kolkr"
    end
    account_id = params[:ugroup_id]
    account = Account.find(account_id)

    current_terms = @domain_root_account.
      enrollment_terms.
      active.
      where("(start_at<=? OR start_at IS NULL) AND (end_at >=? OR end_at IS NULL) AND NOT (start_at IS NULL AND end_at IS NULL)", Time.now.utc, Time.now.utc).
      limit(2).
      to_a
    @current_term = current_terms.length == 1 ? current_terms.first : nil
    courses_info = []
    if @current_term
      if account.grants_any_right?(@current_user, :point_journal_edit, :point_journal_view )
        courses = Course.active.for_term(@current_term)
                        .joins(:course_ext)
                        .joins("INNER JOIN isu_tblvdkr ON isu_tblvdkr.isu_tblvdkr_id = course_exts.isu_tblvdkr_id")
                        .joins("INNER JOIN isu_prk ON isu_prk.isu_prk_id = isu_tblvdkr.kpr")
                        .select(select_columns)
                        .where("courses.account_id = ?", account_id)
      else
        ids = [@current_user.id]
        courses = Course.active.by_teachers_or_assistants(ids).for_term(@current_term)
                        .joins(:course_ext)
                        .joins("INNER JOIN isu_tblvdkr ON isu_tblvdkr.isu_tblvdkr_id = course_exts.isu_tblvdkr_id")
                        .joins("INNER JOIN isu_prk ON isu_prk.isu_prk_id = isu_tblvdkr.kpr")
                        .select(select_columns)
                        .where(:account_id => account_id)
      end
      if @locale == "tj"
        courses = courses_name_to_utf8(courses)
      end
      courses_info = course_info(courses, account_id)
      season_start_date = @current_term.start_at
    end

    render :json => courses_json(courses_info, season_start_date)

  end

  def course_info(courses, account_id)
    data = []
    courses.map do |course|
      array_names = []
      names = ""
      teachers = course.teachers
      teachers.map do |teacher|
        teacher_pseudonym = teacher.pseudonym
        sot_id = get_uchproc_sot_id(teacher_pseudonym)
        array_names << get_uchproc_user_name(sot_id)
      end
      ta_enrollments = course.ta_enrollments
      ta_enrollments.map do |ta_enrollment|
        teacher_assistent = ta_enrollment.user
        assistent_pseudonym = teacher_assistent.pseudonym
        sot_id = get_uchproc_sot_id(assistent_pseudonym)
        array_names << get_uchproc_user_name(sot_id)
      end
      names = array_names.join(",")
      data << {:group_id => account_id, :course_name => course.name, :teacher_name => names, :course_id => course.id, :kolkr => course.kolkr, :start_date => @current_term.start_at}
    end
    data
  end

  def courses_for_att_current_period
    season = UchprocAcademicYear.first
    group_id = params[:ugroup_id]
    courses = UchprocIsuTblvdtkr.select('isu_tblvdtkr.isu_tblvdtkr_id as isu_tblvdkr_id,isu_tblvdtkr.kgr, isu_prk.npr, isu_sot.nst, isu_tblvdtkr.kolkr')
                                .joins(:uchproc_course)
                                .joins(:uchproc_user)
                                .where('kgr = ? and isu_tblvdtkr.chruchgod = ?', group_id, season.last_season_name)


    render :json => courses_json(courses, "")

  end
  def get_uchproc_user_name(sot_id)
    uchproc_user = UchprocUser.where("isu_sot.isu_sot_id = ?", sot_id).first
    uchproc_user_name = ""
    if uchproc_user
      if @locale == "tj"
        uchproc_user_name = convert_to_utf8(uchproc_user.nstt.strip)
      else
        uchproc_user_name = uchproc_user.nst.strip
      end
    end
    uchproc_user_name
  end
  def courses_name_to_utf8(courses)
    courses.map do |course|
      course.name = convert_to_utf8(course.name)
    end
    courses
  end
  def convert_to_utf8(str)
    str = str.gsub("R", "Қ")
    str = str.gsub("r", "қ")
    str = str.gsub("B", "Ӣ")
    str = str.gsub("b", "ӣ")
    str = str.gsub("X", "Ҷ")
    str = str.gsub("x", "ҷ")
    str = str.gsub("[", "Ҳ")
    str = str.gsub("{", "ҳ")
    str = str.gsub("E", "Ӯ")
    str = str.gsub("e", "ӯ")
    str = str.gsub("U", "Ғ")
    str = str.gsub("u", "ғ")

    str
  end
  def get_uchproc_sot_id(teacher_pseudonym)
    sis_user_id = teacher_pseudonym.sis_user_id
    uchproc_sot_id = 0
    if sis_user_id.length > 4
      uchproc_sot_id = sis_user_id[4..-1].to_i
    end
    uchproc_sot_id
  end

end

