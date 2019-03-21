class CreateRussellLists < ActiveRecord::Migration
  def change
    create_table :russell_lists do |t|
      t.text :syms

      t.timestamps null: false
    end
  end
end
