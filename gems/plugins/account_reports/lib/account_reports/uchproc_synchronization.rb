require 'account_reports/report_helper'

module AccountReports

  class UchprocSync
    include ReportHelper
    include ActionController

    LIST_SYNC = ["faculty", "specialty", "kurs", "groups", "students", "teachers","terms", "courses", "recount_assessments"].freeze

    def initialize(account_report, runner=nil)
      @account_report = account_report
      @reports = LIST_SYNC & @account_report.parameters.select { |_k, v| value_to_boolean(v) }.keys
      @include_deleted = value_to_boolean(account_report.parameters&.dig('include_deleted'))
      @record_id = account_report.parameters&.dig('record_id')
      term
      @context = account_report.account.root_account
      @domain_root_account
      @current_user = @account_report.user
    end

    def start_sync
      @reversed = []
      report_extra_text
      @reports.each do |n|
        case n
        when 'faculty'
          faculty
        when 'specialty'
          specialty
        when 'kurs'
          kurs
        when "groups"
          groups
        when 'students'
          students
        when 'teachers'
          teachers
        when 'terms'
          terms
        when "courses"
          courses
        when "recount_assessments"
          recount_assessments
        when "test"
          test_run
        else
          Rails.logger.info "method  #{n} is not exists"
        end
      end
      headers = []
      headers << I18n.t('#account_reports.report_header_1', 'Type')
      headers << I18n.t('#account_reports.report_header_2', 'Reversed')

      write_report headers do |csv|
        @reversed.each do |u|
          row = []
          row << u["type"]
          row << u["count"]
          csv << row
        end
      end
    end
    def test_run
      Rails.logger.info "Run Test Job!!!!"
    end
    def faculty
      facultyes = nil
      if @record_id
        facultyes ||= UchprocFaculty.where(:isu_fak_id => @record_id)
      else
        facultyes ||= UchprocFaculty.all
      end
      parent_account = @context.id
      facultyes.map do |faculty|
        @sub_account = nil
        @sub_account ||= create_sub_account(parent_account, faculty.nfk.strip, "fak_#{faculty.isu_fak_id}")
        if @sub_account
          account_ext = @sub_account.account_ext
          if account_ext
            if account_ext.update(:code => faculty.kfk)
              add_or_update_trl(account_ext.id, 'ru', 'short_name', faculty.snfk.strip)
              add_or_update_trl(account_ext.id, 'ru', 'name', faculty.nfk.strip)
              add_or_update_trl(account_ext.id, 'tj', 'short_name', Uchproc::UchprocHelper.convert_to_utf8(faculty.snfkt.strip))
              add_or_update_trl(account_ext.id, 'tj', 'name', Uchproc::UchprocHelper.convert_to_utf8(faculty.nfkt.strip))
            end
          else
            account_ext ||= AccountExt.new(:integration_id => faculty.isu_fak_id, :code => faculty.kfk, :account => @sub_account)
            account_ext[:integration_id] = faculty.isu_fak_id
            account_ext[:code] = faculty.kfk
            account_ext[:account_id] = @sub_account.id
            if account_ext.save!
              add_or_update_trl(account_ext.id, 'ru', 'short_name', faculty.snfk.strip)
              add_or_update_trl(account_ext.id, 'ru', 'name', faculty.nfk.strip)
              add_or_update_trl(account_ext.id, 'tj', 'short_name', Uchproc::UchprocHelper.convert_to_utf8(faculty.snfkt.strip))
              add_or_update_trl(account_ext.id, 'tj', 'name', Uchproc::UchprocHelper.convert_to_utf8(faculty.nfkt.strip))
            end
          end
        end
      end
      if facultyes
        @reversed << {:type => 'faculty', :count => facultyes.length}
      end
    end

    def specialty
      specialtyes = nil
      if @record_id
        specialtyes ||= UchprocSpecialty.where(:isu_spe_id => @record_id)
      else
        specialtyes ||= UchprocSpecialty.all
      end
      specialtyes.map do |specialty|
        sis = "fak_#{specialty.kfk}"
        parent_account = Account.where(sis_source_id: sis).first
        name = "#{specialty.nsp.strip}(#{specialty.ksp.strip})"
        if parent_account
          @sub_account = nil
          @sub_account = create_sub_account(parent_account.id, name, "spe_#{specialty.isu_spe_id}")
          if @sub_account
            account_ext = @sub_account.account_ext
            if account_ext
              if account_ext.update(:code => specialty.ksp)
                add_or_update_trl(account_ext.id, 'ru', 'short_name', specialty.snsp.strip)
                add_or_update_trl(account_ext.id, 'ru', 'name', specialty.nsp.strip)
                add_or_update_trl(account_ext.id, 'tj', 'short_name', Uchproc::UchprocHelper.convert_to_utf8(specialty.snspt.strip))
                add_or_update_trl(account_ext.id, 'tj', 'name', Uchproc::UchprocHelper.convert_to_utf8(specialty.nspt.strip))
              end
            else
              account_ext ||= AccountExt.new(:integration_id => specialty.isu_spe_id, :code => specialty.ksp, :account => @sub_account)
              if account_ext.save!
                add_or_update_trl(account_ext.id, 'ru', 'short_name', specialty.snsp.strip)
                add_or_update_trl(account_ext.id, 'ru', 'name', specialty.nsp.strip)
                add_or_update_trl(account_ext.id, 'tj', 'short_name', Uchproc::UchprocHelper.convert_to_utf8(specialty.snspt.strip))
                add_or_update_trl(account_ext.id, 'tj', 'name', Uchproc::UchprocHelper.convert_to_utf8(specialty.nspt.strip))
              end
            end
          end
        else
          Rails.logger.info "specialty by sis #{sis} is not exist"
        end
      end
    end
    def kurs
      kurses = nil
      if @record_id
        kurses ||= UchprocClass.where(:isu_krs_id => @record_id)
      else
        kurses ||= UchprocClass.all
      end
      kurses.map do |kurs|
        sis = "spe_#{kurs.ksp}"
        name = kurs.kkr
        parent_account = Account.where(sis_source_id: sis).first
        if parent_account
          @sub_account = nil
          @sub_account =  create_sub_account(parent_account.id, name, "krs_#{kurs.isu_krs_id}")
        else
          Rails.logger.info "specialty by sis #{sis} is not exist"
        end
      end
    end
    def groups
      groups = nil
      if @record_id
        groups ||= UchprocGroup.where(:isu_grp_id => @record_id)
      else
        groups ||= UchprocGroup.all
      end
      groups.map do |group|
        sis = "krs_#{group.kkr}"
        name = group.kgr
        parent_account = Account.where(sis_source_id: sis).first
        if parent_account
          create_sub_account(parent_account.id, name, "grp_#{group.isu_grp_id}")
        else
          Rails.logger.info "kurs by sis #{sis} is not exist"
        end
      end
    end
    def students
      students = nil
      if @record_id
        students ||= UchprocStudent.where(:isu_std_id => @record_id)
      else
        students ||= UchprocStudent.all
      end
      students.map do |student|
        if @record_id
          @pseudonym = student.get_pseudonym(@context)
        end
        @tcontext = student.get_group
        if @tcontext
          if @record_id && @pseudonym
            user = @pseudonym&.user
            if user && !@tcontext.associated_user?(user)
              user.remove_from_root_account(:all)
            end
            @user = student.update_to_canvas(@context)
          else
            @user = student.add_to_canvas(@context)
          end
          if @user
            @account_member = @tcontext
            if !@tcontext.associated_user?(@user)
              @account_member = add_account_user("StudentEnrollment")
            end
            if @account_member
              if student.chactive.strip.to_i == 3
                @user.remove_from_root_account(:all)
              else
                term = active_term
                if term
                  courses = @account_member.courses.for_term(term)
                  courses.map do |course|
                    course.enroll_student(@user, :enrollment_state => 'active')
                  end
                end
              end
            else
              Rails.logger.info "User don't added to group #{@tcontext.id}"
            end
          end
        end
      end
    end
    def teachers
      sots = nil
      if @record_id
        sots ||= UchprocUser.where(:isu_sot_id => @record_id)
      else
        sots ||= UchprocUser.all
      end
      sots.map do |sot|
        sis = "tch_#{sot.isu_sot_id}";
        if @record_id
          @pseudonym = @context.pseudonyms.where(:sis_user_id => sis).first
        end
        if @record_id && @pseudonym
          @user = sot.update_to_canvas(@context, "tch")
        else
          @user = sot.add_to_canvas(@context, "tch")
        end
      end
    end

    def terms
      terms = nil
      if @record_id
        terms ||= UchprocAcademicYear.where(:isu_ugd_id => @record_id)
      else
        terms ||= UchprocAcademicYear.all
      end
      @term_new = nil
      terms.map do |term|
        name = term.ses + term.ucg
        start_at = term.ducgn.strftime('%F')
        end_at = term.ducgk.strftime('%F')
        if start_at
          start_at = start_at + "T06:00"
        end
        if end_at
          end_at = end_at + "T06:00"
        end
        sis = "term_#{term.isu_ugd_id}"
        if @record_id
          @term_new = @context.enrollment_terms.active.where(:sis_source_id => sis).first
        end
        params = ActionController::Parameters.new(enrollment_term: {name: name, start_at: start_at, end_at: end_at, sis_term_id: sis, term_code: name,
                                                                    overrides:{StudentEnrollment: {start_at: start_at, end_at: end_at},
                                                                               TeacherEnrollment: {start_at: start_at, end_at: end_at},
                                                                               TaEnrollment: {start_at: start_at, end_at: end_at},
                                                                               DesignerEnrollment: {start_at: start_at, end_at: end_at}}})

        add_or_update_term(params)
      end

    end
    def courses
      if @term
        if @term.end_at > Time.now
          if @term.term_code.nil?
            name = @term.name
          else
            name = @trem.term_code
          end
          courses = nil
          if @record_id
            courses ||= UchprocIsuTblvdkr.where("chruchgod = '#{name}' AND isu_tblvdkr_id IN (#{@record_id})")
          else
            courses ||= UchprocIsuTblvdkr.where(:chruchgod => name)
          end
          courses.map do |course|
            subject = course.uchproc_course
            sis = "cur_#{course.isu_tblvdkr_id}"
            vt_course = UchprocIsuTblvdtkr.where(:chruchgod => name, :kst => course.kst, :kpr => course.kpr, :kgr => course.kgr).first
            group = course.uchproc_group
            format = group.uchproc_class.get_format_course
            if group
              @sub_account = Account.where(sis_source_id: "grp_#{group.id}").first
              tch_user_pseudonym = @context.pseudonyms.where(sis_user_id: "tch_#{course.kst}").first
              if course.kas != 0 && ta_user_pseudonym = @context.pseudonyms.where(sis_user_id: "tch_#{course.kas}").first
                @assistant = ta_user_pseudonym.user
              else
                @assistant = nil
              end
              if tch_user_pseudonym
                @teacher = tch_user_pseudonym.user
              else
                @teacher = nil
              end
              if subject
                if group.kgr.start_with?('Р')
                  subject_name = Uchproc::UchprocHelper.convert_to_utf8(subject.npr.strip)
                else
                  subject_name = Uchproc::UchprocHelper.convert_to_utf8(subject.nprt.strip)
                end
              end

              if !@teacher.nil? && !@sub_account.nil? && subject
                params = ActionController::Parameters.new(:account_id => @context.id, course: {:name => subject_name, :course_code => course.nvd.strip, :is_public_to_auth_users => true,
                                                                                               :term_id => @term.id, :sis_course_id => sis, :account_id => @sub_account.id,
                                                                                               :start_at => @term.start_at, :end_at => @term.end_at, :course_format => format})
                @course = nil
                @course = create_course(params)
                if @course
                  account_students = @sub_account.active_account_users.where(role_id: 3)
                  account_students.map do |acc_student|
                    @course.enroll_student(acc_student.user, :enrollment_state => 'active')
                  end
                  teacher_enrollments = @course.teacher_enrollments
                  ta_enrollments = @course.ta_enrollments
                  if teacher_enrollments
                    teacher_enrollments.map do |teacher_enrollment|
                      if (teacher_enrollment.user != @teacher && teacher_enrollment.user != @assistant) && teacher_enrollment.can_be_deleted_by(@current_user, @course, nil)
                        teacher_enrollment.destroy
                      end
                    end
                  end
                  if ta_enrollments
                    ta_enrollments.map do |teacher_enrollment|
                      if (teacher_enrollment.user != @teacher && teacher_enrollment.user != @assistant) && teacher_enrollment.can_be_deleted_by(@current_user, @course, nil)
                        teacher_enrollment.destroy
                      end
                    end
                  end
                  #end
                  c = @course.course_ext
                  c ||= CourseExt.new(:course => @course)
                  if c
                    if vt_course
                      c['isu_tblvdtkr_id'] = vt_course.isu_tblvdtkr_id
                    end
                    c['isu_tblvdkr_id'] = course.isu_tblvdkr_id
                    c['kolkr'] = course.kolkr.to_i
                    if c.save!
                      Rails.logger.info "Course ext #{{:course_ext => c}} added"
                    end
                  end
                end
                @course.update(:workflow_state => 'available')
              end
            end
          end
        end
      end
    end
    def create_sub_account(parent_account_id, name, sis)
      @sub_account = Account.where(sis_source_id: sis).first
      if @sub_account
        if @sub_account.update(:name => name, :parent_account_id => parent_account_id.to_i)
          Rails.logger.info "Account updated!!"
        end
      else
        account_id = parent_account_id.to_i
        @parent_account = Account.find(account_id)
        @sub_account = @parent_account.sub_accounts.new
        @sub_account.root_account = @context
        @sub_account.name = name
        @sub_account.sis_source_id = sis
        @sub_account.integration_id = sis
        @sub_account.parent_account_id = account_id
        if @sub_account.save!
          Rails.logger.info "sub_account #{@sub_account.id} is create"
        else
          Rails.logger.info "sub_account #{@sub_account.name} #{@sub_account.sis_source_id} don`t created!!!"
        end
      end
      @sub_account
    end
    def create_groups_categories(parent_account_id, root_account_id, name, sis)
      @parent_account = Account.find(parent_account_id.to_i)
      @group_categories = @parent_account.group_categories.build
      @group_categories.name = name
      @group_categories.sis_source_id = sis
      @group_categories.root_account_id = root_account_id

      if @group_categories.save!
        Rails.logger.info "group categories #{@group_categories.id} is create"
      else
        Rails.logger.info "group categories #{@group_categories.name} don`t created!!!"
      end
    end
    def create_groups(root_account_id, group_categories_id, name, sis)
      @group_categories = GroupCategory.find(group_categories_id)
      @context = @group_categories.account
      @group = @group_categories.groups.build
      @group.name = name
      @group.category = @group_categories.name
      @group.is_public = false
      @group.root_account_id = root_account_id
      @group.context =  @context
      @group.sis_source_id = sis
      @group.description = 'Group for students'
      #@group.workflow_state = 'accepted'

      if @group.save!
        Rails.logger.info "group  #{@group.id} is create"
      else
        Rails.logger.info "group  #{@group.name} don`t created!!!"
      end
    end
    def create_course(params)
      @account = params[:account_id] ? api_find(Account, params[:account_id]) : @domain_root_account.manually_created_courses_account
      params[:course] ||= {}
      params_for_create = course_params(params)

      if params_for_create.has_key?(:syllabus_body)
        params_for_create[:syllabus_body] = process_incoming_html_content(params_for_create[:syllabus_body])
      end

      if params_for_create.key?(:grade_passback_setting)
        grade_passback_setting = params_for_create.delete(:grade_passback_setting)
        return unless authorized_action?(@course, @current_user, :manage_grades)
        update_grade_passback_setting(grade_passback_setting)
      end

      if (sub_account_id = params[:course].delete(:account_id)) && sub_account_id.to_i != @account.id
        @sub_account = @account.find_child(sub_account_id)
      end

      term_id = params[:course].delete(:term_id).presence || params[:course].delete(:enrollment_term_id).presence
      params_for_create[:enrollment_term] = api_find(@account.root_account.enrollment_terms, term_id) if term_id

      sis_course_id = params[:course].delete(:sis_course_id)
      apply_assignment_group_weights = params[:course].delete(:apply_assignment_group_weights)


      course_end = if params[:course][:end_at].present?
                     params_for_create[:conclude_at] = params[:course].delete(:end_at)
                     :end_at
                   else
                     :conclude_at
                   end

      unless @account.grants_right? @current_user, :manage_storage_quotas
        params_for_create.delete :storage_quota
        params_for_create.delete :storage_quota_mb
      end


      can_manage_sis =  @context.grants_right?(@current_user, :manage_sis)
      if can_manage_sis && value_to_boolean(params[:enable_sis_reactivation])
        @course = @domain_root_account.all_courses.where(
          :sis_source_id => sis_course_id, :workflow_state => 'deleted'
        ).first
        if @course
          @course.workflow_state = 'claimed'
          @course.account = @sub_account if @sub_account
        end
      end
      @course ||=  @domain_root_account.all_courses.where(
        :sis_source_id => sis_course_id
      ).first
      if @course
        @course.name = params[:course][:name]
      end

      @course ||= (@sub_account || @account).courses.build(params_for_create)

      if can_manage_sis && !@course.sis_source_id
        @course.sis_source_id = sis_course_id
      end
      if apply_assignment_group_weights
        @course.apply_assignment_group_weights = value_to_boolean apply_assignment_group_weights
      end
      changes = changed_settings(@course.changes, @course.settings)
      if @course.save
        @course.enroll_user(@teacher, 'TeacherEnrollment', :enrollment_state => 'active') if @teacher
        @course.enroll_user(@assistant, 'TaEnrollment', :enrollment_state => 'active') if @assistant
        @course.require_assignment_group rescue nil
      else
        # flash[:error] = t('errors.create_failed', "Course creation failed")
        Rails.logger.info "Course error #{{:error => @course.errors}}"
      end
      @course
    end
    def recount_assessments
      unless @term
        return
      end
      courses = Course.active.for_term(@term)
      courses.map do |course|
        course_id = course.id
        course_ext = CourseExt.where(:course_id => course_id).first
        if course_ext
          kvd = course_ext.isu_tblvdkr_id
          att_kvd = course_ext.isu_tblvdtkr_id
        end
        if kvd
          academic_plan_and_class = UchprocPointJournal.course_academic_plan_class(kvd)
          if academic_plan_and_class
            season_study_weeks = UchprocAcademicPlan.season_study_weeks(academic_plan_and_class[:academic_plan_id],
                                                                        academic_plan_and_class[:class_number], [], course_id)
            if season_study_weeks
              current_week_number = UchprocAcademicYear.current_week_number(course_id)
              points = UchprocPointJournal.where(kvd: kvd)
              points.map do |student|
                UchprocPointJournal.recount_results_and_assessment(student, season_study_weeks, course_id, current_week_number)
              end
            end
          end
        end
      end
    end
    def add_account_user(role_name)
      role = Role.get_built_in_role(role_name)
      context = @tcontext
      if role && context && @user
        admin = context.account_users.where(:user => @user, :role => role).first_or_initialize
        admin.workflow_state = 'active'
        if admin.new_record? || admin.workflow_state_changed?
          if admin.save
            acc_user = { :enrollment => {
              :id => admin.id,
              :name => admin.user.name,
              :role_id => admin.role_id,
              :membership_type => AccountUser.readable_type(admin.role.name),
              :workflow_state => 'active',
              :user_id => admin.user.id,
              :type => 'admin',
              :email => admin.user.email
            }}
          end
        end
      end
      context
    end
    def add_user_to_group(new_record_state=nil, moderator=nil)
      return nil if !@user
      attrs = {:user_id => @pseudonym.map(&:user_id),
               :workflow_state => :active, :moderator => !!moderator }
      new_record_state ||= 'invited'
      attrs[:workflow_state] = new_record_state if new_record_state

      member = @group.group_memberships.where(user_id: @user).first
      if member
        member.workflow_state = new_record_state unless member.active?
        # only update moderator if true/false is explicitly passed in
        member.moderator = moderator unless moderator.nil?
        member.save if member.changed?
      else
        member = @group.group_memberships.create(attrs)
      end
      # permissions for this user in the group are probably different now
      clear_permissions_cache(@user)
      return member
    end
    def add_student_to_group(user_id, group_id)
      @member_to_group = nil
      @member_to_group = GroupMembership.where(group_id: group_id, user_id: user_id)
      if @member_to_group.nil?
        member = GroupMembership.new(group_id: group.id, user_id: user.id)
        member.save!
      end
    end
    def add_or_update_term(params)
      params.require(:enrollment_term)
      overrides = params[:enrollment_term][:overrides]&.to_unsafe_h
      if overrides.present?
        unless (overrides.keys.map(&:classify) - %w(StudentEnrollment TeacherEnrollment TaEnrollment DesignerEnrollment)).empty?
          Rails.logger.info "#{{:message => 'Invalid enrollment type in overrides'}}"
        end
      end
      sis_id = params[:enrollment_term][:sis_source_id] || params[:enrollment_term][:sis_term_id]
      if sis_id && !(sis_id.is_a?(String) || sis_id.is_a?(Numeric))
        Rails.logger.info "#{{:message => "Invalid SIS ID"}}"
      end
      if @term_new.nil?
        @term_new = @context.enrollment_terms.active.build
        handle_sis_id_param(sis_id)
      end
      term_params = params.require(:enrollment_term).permit(:name, :start_at, :end_at)
      DueDateCacher.with_executing_user(@current_user) do
        if validate_dates(@term_new, term_params, overrides) && @term_new.update(term_params)
          @term_new.set_overrides(@context, overrides)
        else
          Rails.logger.info "#{@term_new.errors}"
        end
      end
    end
    def change_password

    end
    def handle_sis_id_param(sis_id)
      if sis_id &&
        sis_id != @context.sis_source_id &&
        @context.root_account.grants_right?(@current_user, :manage_sis)
        @term_new.sis_source_id = sis_id.presence
        if @term_new.sis_source_id && @term_new.sis_source_id_changed?
          scope = @term_new.root_account.enrollment_terms.where(sis_source_id: @term_new.sis_source_id)
          scope = scope.where("id<>?", @term_new) unless @term_new.new_record?
          @term_new.errors.add(:sis_source_id,  "SIS ID is already in use") if scope.exists?
          @term_new.errors.add(:sis_source_id,  "SIS ID is already in use") if scope.exists?
        end
      end
    end
    def add_or_update_trl(account_ext, lang, column_name, value)
      trl = AccountExtTrl.where(:lang => lang, :column_name => column_name, :account_ext_id => account_ext).first
      if trl
        trl.update(:value => value)
      else
        trl = AccountExtTrl.new(:lang => lang,:account_ext_id => account_ext, :column_name => column_name, :value => value)
        trl.save!
      end
    end
    def validate_dates(term, term_params, overrides)
      hashes = [term_params]
      hashes += overrides.values if overrides
      invalid_dates = hashes.any? do |hash|
        start_at = DateTime.parse(hash[:start_at]) rescue nil
        end_at = DateTime.parse(hash[:end_at]) rescue nil
        start_at && end_at && end_at < start_at
      end
      term.errors.add(:base, t("End dates cannot be before start dates")) if invalid_dates
      !invalid_dates
    end
    def course_params(params)
      return {} unless params[:course]
      params[:course].permit(:name, :group_weighting_scheme, :start_at, :conclude_at,
                             :grading_standard_id, :grade_passback_setting, :is_public, :is_public_to_auth_users, :allow_student_wiki_edits, :show_public_context_messages,
                             :syllabus_body, :syllabus_course_summary, :public_description, :allow_student_forum_attachments, :allow_student_discussion_topics, :allow_student_discussion_editing,
                             :show_total_grade_as_points, :default_wiki_editing_roles, :allow_student_organized_groups, :course_code, :default_view,
                             :open_enrollment, :allow_wiki_comments, :turnitin_comments, :self_enrollment, :license, :indexed,
                             :abstract_course, :storage_quota, :storage_quota_mb, :restrict_enrollments_to_course_dates, :use_rights_required,
                             :restrict_student_past_view, :restrict_student_future_view, :grading_standard, :grading_standard_enabled,
                             :locale, :integration_id, :hide_final_grades, :hide_distribution_graphs, :lock_all_announcements, :public_syllabus, :quiz_engine_selected,
                             :public_syllabus_to_auth, :course_format, :time_zone, :organize_epub_by_content_type, :enable_offline_web_export,
                             :show_announcements_on_home_page, :home_page_announcement_limit, :allow_final_grade_override, :filter_speed_grader_by_student_group,:attendance_point_journal_relation, :journal_point_type
      )
    end
    def update_grade_passback_setting(grade_passback_setting)
      valid_states = Setting.get('valid_grade_passback_settings', 'nightly_sync,disabled').split(',')
      unless grade_passback_setting.blank? || valid_states.include?(grade_passback_setting)
        @course.errors.add(:grade_passback_setting, t("Invalid grade_passback_setting"))
      end
      @course.grade_passback_setting = grade_passback_setting.presence
    end
    def changed_settings(changes, new_settings, old_settings=nil)
      # frd? storing a hash?
      # Settings is stored as a hash in a column which
      # causes us to do some more work if it has been changed.

      # Since course uses write_attribute on settings its not accurate
      # so just ignore it if its in the changes hash
      changes.delete("settings") if changes.has_key?("settings")

      unless old_settings == new_settings
        settings = Course.settings_options.keys.inject({}) do |results, key|
          if old_settings.present? && old_settings.has_key?(key)
            old_value = old_settings[key]
          else
            old_value = nil
          end

          if new_settings.present? && new_settings.has_key?(key)
            new_value = new_settings[key]
          else
            new_value = nil
          end

          results[key.to_s] = [ old_value, new_value ] unless old_value == new_value

          results
        end
        changes.merge!(settings)
      end

      changes
    end

    def active_term
      current_terms = @context.
        enrollment_terms.
        active.
        where("(start_at<=? OR start_at IS NULL) AND (end_at >=? OR end_at IS NULL) AND NOT (start_at IS NULL AND end_at IS NULL)", Time.now.utc, Time.now.utc).
        limit(2).
        to_a
      current_term = current_terms.length == 1 ? current_terms.first : nil
      current_term
    end
  end
end


