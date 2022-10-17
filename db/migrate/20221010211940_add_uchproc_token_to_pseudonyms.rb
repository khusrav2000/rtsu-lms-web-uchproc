class AddUchprocTokenToPseudonyms < ActiveRecord::Migration[6.0]
  tag :predeploy

  def change
    add_column :pseudonyms, :uchproc_token, :string, limit: 255
  end
end