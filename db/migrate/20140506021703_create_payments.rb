class CreatePayments < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.string  :reference_id
      t.integer :user_id

      t.timestamps
    end
  end
end
