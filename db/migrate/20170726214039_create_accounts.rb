class CreateAccounts < ActiveRecord::Migration[5.1]
  def change
    create_table :accounts do |t|

      t.integer :user_id
      t.string :account_type

      t.string :name
      t.string :display_name

      t.string :key
      t.string :secret

      t.integer :followers_count
      t.integer :friends_count

      t.timestamps
    end
  end
end
