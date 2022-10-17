require 'atom'
class AccountExt < ActiveRecord::Base
  belongs_to :account
  belongs_to :account_ext_trl
end
