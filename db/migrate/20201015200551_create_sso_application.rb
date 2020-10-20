class CreateSsoApplication < ActiveRecord::Migration[5.2]
  def change
    create_table :sso_applications do |t|
      t.string :name
      t.timestamps null: false
    end

    add_index :sso_applications, :name
  end
end
