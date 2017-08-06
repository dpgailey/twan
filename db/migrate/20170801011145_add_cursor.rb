class AddCursor < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :cursor, :string
  end
end
