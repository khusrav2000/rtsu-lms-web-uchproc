module  Uchproc
  class UchprocUser
    def initialize(account = nil)
      @account = account
      @account ||= Account.root_accounts.where(:id => 1).order(:id).first
    end
    def add_user(params)
      params[:pseudonym] ||= {}
      params[:pseudonym][:unique_id].strip! if params[:pseudonym][:unique_id].is_a?(String)
      sis_user_id = params[:pseudonym].delete(:sis_user_id)
      integration_id = params[:pseudonym].delete(:integration_id)
      uchproc_token = params[:pseudonym].delete(:uchproc_token)
      @pseudonym = nil
      @user = nil
      if sis_user_id && value_to_boolean(params[:enable_sis_reactivation])
        @pseudonym = @account.pseudonyms.where(:sis_user_id => sis_user_id, :workflow_state => 'deleted').first
        if @pseudonym
          @pseudonym.workflow_state = 'active'
          @pseudonym.save!
          @user = @pseudonym.user
          @user.workflow_state = 'registered'
          @user.update_account_associations
          if params[:user]&.dig(:skip_registration) && params[:communication_channel]&.dig(:skip_confirmation)
            cc = CommunicationChannel.where(user_id: @user.id, path_type: :email).order(updated_at: :desc).first
            if cc
              cc.pseudonym = @pseudonym
              cc.workflow_state = 'active'
              cc.save!
            end
          end
        end
      end
      Rails.logger.info "Account IS #{{:account => @account}}"
      Rails.logger.info "Pseudonym is #{{:ps => @pseudonym}}"
      Rails.logger.info "Unique is #{{:un => params[:pseudonym][:unique_id]}}"
      if @pseudonym.nil?
        @pseudonym = @account.pseudonyms.active.by_unique_id(params[:pseudonym][:unique_id]).first
        # Setting it to nil will cause us to try and create a new one, and give user the login already exists error
        #@pseudonym = nil if @pseudonym && @record_id.nil? && !['creation_pending', 'pending_approval'].include?(@pseudonym.user.workflow_state)
        @pseudonym = nil if @pseudonym && !['creation_pending', 'pending_approval'].include?(@pseudonym.user.workflow_state)
      end

      Rails.logger.info "Pseudonym IS #{{:user => @pseudonym}}"
      @user ||= @pseudonym&.user
      @user ||= @account.shard.activate { User.new }
      #Rails.logger.info "user is #{{us: => @user}}"
      use_pairing_code = params[:user] && params[:user][:initial_enrollment_type] == 'observer' && @domain_root_account.self_registration?
      force_validations = value_to_boolean(params[:force_validations])
      manage_user_logins = true
      self_enrollment = params[:self_enrollment].present?
      allow_non_email_pseudonyms = !force_validations && manage_user_logins || self_enrollment && params[:pseudonym_type] == 'username'
      require_password = self_enrollment && allow_non_email_pseudonyms
      allow_password = require_password || manage_user_logins || use_pairing_code

      notify_policy = Users::CreationNotifyPolicy.new(manage_user_logins, params[:pseudonym])

      includes = %w{locale}

      cc_params = params[:communication_channel]
      if cc_params
        cc_type = cc_params[:type] || CommunicationChannel::TYPE_EMAIL
        cc_addr = cc_params[:address] || params[:pseudonym][:unique_id]

        if cc_type == CommunicationChannel::TYPE_EMAIL
          cc_addr = nil unless EmailAddressValidator.valid?(cc_addr)
        end

        can_manage_students = [Account.site_admin, @account].any? do |role|
          role.grants_right?(@current_user, :manage_students)
        end

        if can_manage_students || use_pairing_code
          skip_confirmation = value_to_boolean(cc_params[:skip_confirmation])
        end

        if can_manage_students && cc_type == CommunicationChannel::TYPE_EMAIL
          includes << 'confirmation_url' if value_to_boolean(cc_params[:confirmation_url])
        end

      else
        cc_type = CommunicationChannel::TYPE_EMAIL
        cc_addr = params[:pseudonym].delete(:path) || params[:pseudonym][:unique_id]
        cc_addr = nil unless EmailAddressValidator.valid?(cc_addr)
      end
      if params[:user]
        user_params = params[:user]
        if self_enrollment && user_params[:self_enrollment_code]
          user_params[:self_enrollment_code].strip!
        else
          user_params.delete(:self_enrollment_code)
        end
        if user_params[:birthdate].present? && user_params[:birthdate] !~ Api::ISO8601_REGEX &&
            user_params[:birthdate] !~ Api::DATE_REGEX
        end

        @user.attributes = user_params
        accepted_terms = params[:user].delete(:terms_of_use)
        @user.accept_terms if value_to_boolean(accepted_terms)
        includes << "terms_of_use" unless accepted_terms.nil?
      end
      @user.name ||= params[:pseudonym][:unique_id]
      skip_registration = value_to_boolean(params[:user].try(:[], :skip_registration))
      unless @user.registered?
        @user.workflow_state = if require_password || skip_registration
                                 # no email confirmation required (self_enrollment_code and password
                                 # validations will ensure everything is legit)
                                 'registered'
                               elsif notify_policy.is_self_registration? && @user.registration_approval_required?
                                 'pending_approval'
                               else
                                 'pre_registered'
                                 Pseudonym
                               end
      end
      if force_validations || !manage_user_logins
        @user.require_acceptance_of_terms = @domain_root_account.terms_required?
        @user.require_presence_of_name = true
        @user.require_self_enrollment_code = self_enrollment
        @user.validation_root_account = @domain_root_account
      end
      @invalid_observee_creds = nil
      @invalid_observee_code = nil
      if @user.initial_enrollment_type == 'observer'
        @pairing_code = ObserverPairingCode.active.where(code: params[:pairing_code][:code]).first
        if !@pairing_code.nil?
          @observee = @pairing_code.user
        else
          @invalid_observee_code = ObserverPairingCode.new
          @invalid_observee_code.errors.add('code', 'invalid')
        end
      end
      @pseudonym ||= @user.pseudonyms.build(:account => @account)
      @pseudonym.account.email_pseudonyms = !allow_non_email_pseudonyms
      @pseudonym.require_password = require_password
      # pre-populate the reverse association
      @pseudonym.user = @user

      pseudonym_params = {password: params[:pseudonym][:password],
                          password_confirmation: params[:pseudonym][:password],
                          unique_id: params[:pseudonym][:unique_id]}

      # don't require password_confirmation on api calls
      # don't allow password setting for new users that are not self-enrolling
      # in a course (they need to go the email route)
      unless allow_password
        pseudonym_params.delete(:password)
        pseudonym_params.delete(:password_confirmation)
      end
      password_provided = @pseudonym.new_record? && pseudonym_params.key?(:password)
      if password_provided && @user.workflow_state == 'pre_registered'
        @user.workflow_state = 'registered'
      end
      if params[:pseudonym][:authentication_provider_id]
        @pseudonym.authentication_provider = @account.
            authentication_providers.active.
            find(params[:pseudonym][:authentication_provider_id])
      end
      @pseudonym.attributes = pseudonym_params
      @pseudonym.sis_user_id = sis_user_id
      @pseudonym.integration_id = integration_id
      @pseudonym.uchproc_token = uchproc_token

      @pseudonym.account = @account
      @pseudonym.workflow_state = 'active'
      if cc_addr.present?
        @cc =
            @user.communication_channels.where(:path_type => cc_type).by_path(cc_addr).first ||
                @user.communication_channels.build(:path_type => cc_type, :path => cc_addr)
        @cc.user = @user
        @cc.workflow_state = skip_confirmation ? 'active' : 'unconfirmed' unless @cc.workflow_state == 'confirmed'
      end

      if @user.valid? && @pseudonym.valid? && @invalid_observee_creds.nil? & @invalid_observee_code.nil?
        # saving the user takes care of the @pseudonym and @cc, so we can't call
        # save_without_session_maintenance directly. we don't want to auto-log-in
        # unless the user is registered/pre_registered (if the latter, he still
        # needs to confirm his email and set a password, otherwise he can't get
        # back in once his session expires)
        #save_without_session_maintenance
        if !@current_user # automagically logged in
          PseudonymSession.new(@pseudonym).save unless @pseudonym.new_record?
        else
          @pseudonym.save_without_session_maintenance
          #@pseudonym.send(:skip_session_maintenance=, true)
        end
        @user.save!

        if @observee && !@user.as_observer_observation_links.where(user_id: @observee, root_account: @account).exists?
          UserObservationLink.create_or_restore(student: @observee, observer: @user, root_account: @account)
          @pairing_code&.destroy
        end

        if notify_policy.is_self_registration?
          registration_params = params.fetch(:user, {}).merge(remote_ip: request.remote_ip, cookies: cookies)
          @user.new_registration(registration_params)
        end
        message_sent = notify_policy.dispatch!(@user, @pseudonym, @cc) if @cc && !skip_confirmation

        data = { :user => @user, :pseudonym => @pseudonym, :channel => @cc, :message_sent => message_sent, :course => @user.self_enrollment_course }
      else
        errors = {
            :errors => {
                :user => @user.errors.as_json[:errors],
                :pseudonym => @pseudonym ? @pseudonym.errors.as_json[:errors] : {},
                :observee => @invalid_observee_creds ? @invalid_observee_creds.errors.as_json[:errors] : {},
                :pairing_code => @invalid_observee_code ? @invalid_observee_code.errors.as_json[:errors] : {}
            }
        }
        Rails.logger.info "#{{:error => errors}}"
        #logger.info "student #{{:user => user}}"
        @user = nil
      end
      @user
    end


    
    def update_user(params)
      params[:pseudonym] ||= {}
      params[:pseudonym][:unique_id].strip! if params[:pseudonym][:unique_id].is_a?(String)
      sis_user_id = params[:pseudonym].delete(:sis_user_id)
      integration_id = params[:pseudonym].delete(:integration_id)
      uchproc_token = params[:pseudonym].delete(:uchproc_token)
      @pseudonym = nil
      @user = nil
      if sis_user_id && value_to_boolean(params[:enable_sis_reactivation])
        @pseudonym = @account.pseudonyms.where(:sis_user_id => sis_user_id, :workflow_state => 'deleted').first
        if @pseudonym
          @pseudonym.workflow_state = 'active'
          @pseudonym.save!
          @user = @pseudonym.user
          @user.workflow_state = 'registered'
          @user.update_account_associations
          if params[:user]&.dig(:skip_registration) && params[:communication_channel]&.dig(:skip_confirmation)
            cc = CommunicationChannel.where(user_id: @user.id, path_type: :email).order(updated_at: :desc).first
            if cc
              cc.pseudonym = @pseudonym
              cc.workflow_state = 'active'
              cc.save!
            end
          end
        end
      end
      if @pseudonym.nil?
        @pseudonym = @account.pseudonyms.active.by_unique_id(params[:pseudonym][:unique_id]).first
      end
      use_pairing_code = params[:user] && params[:user][:initial_enrollment_type] == 'observer' && @domain_root_account.self_registration?
      force_validations = value_to_boolean(params[:force_validations])
      manage_user_logins = true
      self_enrollment = params[:self_enrollment].present?
      allow_non_email_pseudonyms = !force_validations && manage_user_logins || self_enrollment && params[:pseudonym_type] == 'username'
      require_password = self_enrollment && allow_non_email_pseudonyms
      allow_password = require_password || manage_user_logins || use_pairing_code
      pseudonym_params = {password: params[:pseudonym][:password],
                          password_confirmation: params[:pseudonym][:password],
                          unique_id: params[:pseudonym][:unique_id]}
      @pseudonym.attributes = pseudonym_params
      @pseudonym.sis_user_id = sis_user_id
      @pseudonym.integration_id = integration_id
      @pseudonym.uchproc_token = uchproc_token

      @user ||= @pseudonym&.user
      if params[:user]
        user_params = params[:user]
        Rails.logger.info "User Params is #{{:user_params => user_params}}"
        if self_enrollment && user_params[:self_enrollment_code]
          user_params[:self_enrollment_code].strip!
        else
          user_params.delete(:self_enrollment_code)
        end
        if user_params[:birthdate].present? && user_params[:birthdate] !~ Api::ISO8601_REGEX &&
            user_params[:birthdate] !~ Api::DATE_REGEX
        end

        @user.attributes = user_params
        accepted_terms = params[:user].delete(:terms_of_use)
        @user.accept_terms if value_to_boolean(accepted_terms)
        includes << "terms_of_use" unless accepted_terms.nil?
      end
      if force_validations || !manage_user_logins
        @user.require_acceptance_of_terms = @domain_root_account.terms_required?
        @user.require_presence_of_name = true
        @user.require_self_enrollment_code = self_enrollment
        @user.validation_root_account = @domain_root_account
      end
      if @pseudonym.valid?
          @pseudonym.save_without_session_maintenance
      end

      if @user.valid?
        @user.save!
      end
      Rails.logger.info "User 111 is #{{:user => @user}}"
      @user
    end
    def value_to_boolean(value)
      Canvas::Plugin.value_to_boolean(value)
    end
  end
end
