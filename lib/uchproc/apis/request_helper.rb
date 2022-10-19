module Uchproc::Apis::RequestHelper
  @@base_url = "http://192.168.123.37:8022"
  @@service = "mobi"
  require 'uri'
  require 'net/http'
  require 'json'

  def request_error(code) 
    if code == 2
      return {
        :error => "Bad request to uchproc api",
        :status => :bad_request,
        :code => code
      }
    elsif code == 3 
      return {
        :error => "Uchproc api Internal error",
        :code => code
      }
    elsif code == 4
      return {
        :error => "uchproc api not found",
        :code => code
      }
    elsif code == 5
      return {
        :error => "uchproc token unauthorized",
        :code => code,
        :logout => true
      }
    elsif code == 6
      return {
        :error => "uchproc token expired",
        :code => code,
        :logout => true
      }
    elsif code == 7
      return {
        :error => "uchproc user not active",
        :code => code
      }
    elsif code == 8
      return {
        :error => "uchproc api success partialy",
        :code => code
      }
    end
  
  end

  def add_user_and_authorization(login, password)
    
    uri = URI("#{@@base_url}/tokenize")

    body = {}
    body[:external_ref] = "test 1"
    body[:login_pass] = {}
    body[:login_pass][:login] = login
    body[:login_pass][:password] = password
    body[:service_name] = "mobi"

    puts body
    header = {'Content-Type': 'text/json'}
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.request_uri, header)
    req.body = body.to_json
    res = http.request(req)
    puts res.body if res.is_a?(Net::HTTPSuccess)
    res_body = JSON.parse(res.body)
    puts "ds = #{res_body}"
    puts "code = #{res_body["code"]}"
    # add user
    if res_body["code"] == 1
      payload = res_body["payload"]
      isu_sot_id = payload["user_code"]
      full_name = payload["full_name"]
      token = payload["token"]

      enable_sis_reactivation = "1"
      prefix_sis = "tch"
      user_sis = prefix_sis + "_#{isu_sot_id}"
      #correct_name = Uchproc::UchprocHelper.convert_to_utf8(name.strip)
      correct_name = full_name
      sortable_name = correct_name.gsub(" ", ",")
      uch_login = login

      account = Account.root_accounts.where(:id => 1).order(:id).first
      pseudonym = account.pseudonyms.where(:sis_user_id => user_sis).first
      pseudonym ||= account.pseudonyms.by_unique_id(uch_login).first

      if pseudonym
        puts "YS!!!!!!!!!!!!!!!!"
        params = {user: {name: correct_name, short_name: correct_name, sortable_name: sortable_name},
                  time_zone: "Asia/Tashkent", locale: "ru", terms_of_use: "0", skip_registration: "1",
                  pseudonym: {unique_id: uch_login, password: password, sis_user_id: user_sis,
                              integration_id: user_sis, uchproc_token: token},communication_channel: {skip_confirmation: "1"}, enable_sis_reactivation: enable_sis_reactivation}
        @user = Uchproc::UchprocUser.new(account).update_user(params)
      elsif
        params = {user: {name: correct_name, short_name: correct_name, sortable_name: sortable_name},
                      time_zone: "Asia/Tashkent", locale: "ru", terms_of_use: "0", skip_registration: "1",
                      pseudonym: {unique_id: uch_login, password: password, sis_user_id: user_sis,
                                  integration_id: user_sis, uchproc_token: token},communication_channel: {skip_confirmation: "1"}}

        puts "params = #{params}"
        @user = Uchproc::UchprocUser.new().add_user(params)
        puts "user #{@user}"
      end
      
      return 1
    end
    
    return 0
    
  end

  def get_main_filter(token)
    uri = URI("#{@@base_url}/faculties")

    body = {}
    body[:academic_year] = "Л2021/22"
    body[:external_ref] = "test 1"
    body[:service_name] = "mobi"

    puts body
    header = {'Content-Type': 'text/json', "Token": token, "Service": @@service}
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.request_uri, header)
    req.body = body.to_json
    res = http.request(req)
    res_body = JSON.parse(res.body)

    puts "code = #{res_body["code"]}"

    if res_body["code"] == 1
      return {
        :payload => res_body["payload"]
      }
    end
    return request_error(res_body["code"])
  end

  def get_courses_by(group_id, token)
    uri = URI("#{@@base_url}/courses")

    puts group_id
    body = {}
    body[:group_id] = group_id.to_i
    body[:external_ref] = "test 1"
    body[:service_name] = "mobi"
    body[:userUchprocCode] = 0

    puts body
    header = {'Content-Type': 'text/json', "Token": token, "Service": @@service}
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.request_uri, header)
    req.body = body.to_json
    res = http.request(req)
    res_body = JSON.parse(res.body)

    puts "code = #{res_body["code"]}"

    if res_body["code"] == 1
      return {
        :payload => res_body["payload"]["courses"]
      }
    end
    return request_error(res_body["code"])
  end
end