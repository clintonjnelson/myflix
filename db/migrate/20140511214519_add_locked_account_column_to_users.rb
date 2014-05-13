class AddLockedAccountColumnToUsers < ActiveRecord::Migration
  def change
    add_column :users, :locked_account, :boolean
  end
end
