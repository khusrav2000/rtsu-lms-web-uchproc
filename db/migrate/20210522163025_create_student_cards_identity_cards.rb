class CreateStudentCardsIdentityCards < ActiveRecord::Migration[5.2]
  tag :predeploy

  def change
    create_table :student_cards do |t|
      t.integer  "user_id", :limit => 8, :null => false
      t.integer  "account_id", :limit => 8, :null => false
      t.string    "record_book_number", :limit => 12
      t.string   "nationality", :limit => 255
      t.string    "gender", :limit => 20
      t.integer    "country", :limit => 8
      t.string    "region", :limit => 255
      t.string    "address", :limit => 255
      t.datetime  "birthdate"
      t.integer    "birth_country", :limit => 8
      t.string    "birth_region", :limit => 255
      t.string    "birth_address", :limit => 255
      t.string    "marital_status", :limit => 20
      t.string    "circumstance", :limit => 20
      t.text      "family_composition"
      t.string    "financing", :limit => 20
      t.string   "name_tj", :limit => 255
      t.string   "name_ru", :limit => 255
      t.text      "phones"
      t.text      "emails"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer    "created_by", :limit => 8, :null => false
      t.integer    "updated_by", :limit => 8, :null => false
    end
    add_foreign_key :student_cards, :accounts
    add_foreign_key :student_cards, :users
    add_index :student_cards, :user_id
    add_index :student_cards, :account_id

    create_table :identity_cards do |t|
      t.integer  "user_id", :limit => 8, :null => false
      t.string    "series", :limit => 8
      t.string    "number", :limit => 15, :null => false
      t.text      "issuing_authority"
      t.datetime  "date_issue"
      t.datetime  "date_expiry"
      t.string   "identity_type", :limit => 50
      t.string    "enrollment", :limit => 20
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer    "created_by", :limit => 8, :null => false
      t.integer    "updated_by", :limit => 8, :null => false
      t.string    "workflow_state", :limit => 50
    end
    add_foreign_key :identity_cards, :users
    add_index :identity_cards, :user_id
    add_index :identity_cards, :enrollment
  end
end

