class CreateSsoApplicationUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :sso_application_users do |t|
      t.integer :sso_application_id
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
