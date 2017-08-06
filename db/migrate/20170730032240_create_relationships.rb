class CreateRelationships < ActiveRecord::Migration[5.1]
  def change
    create_table :relationships do |t|
      t.integer :user_id
      t.integer :account_id
      # (user_id -> account_id) follower, following
      t.string :relationship_type
      t.timestamps
    end
  end
end
