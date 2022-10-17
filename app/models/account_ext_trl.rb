require 'atom'
class AccountExtTrl < ActiveRecord::Base
  has_many :account_exts

end
