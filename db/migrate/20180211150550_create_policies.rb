class CreatePolicies < ActiveRecord::Migration[5.2]
  def change
    create_table :policies do |t|
      t.integer :user_id
      t.json :data

      t.timestamps
    end
    add_index :policies, [:user_id]
  end
end
