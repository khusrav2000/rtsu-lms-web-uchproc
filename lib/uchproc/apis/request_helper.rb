module Uchproc::Apis::RequestHelper
  @@base_url = "http://192.168.123.37:8022"
  require 'uri'
  require 'net/http'
  require 'json'

  def add_user_and_authorization(login, password)
    puts "its its = #{@@base_url}"
    uri = URI("#{@@base_url}/tokenize")

    puts uri

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
end