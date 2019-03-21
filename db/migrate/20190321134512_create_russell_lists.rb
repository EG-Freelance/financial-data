class CreateRussellLists < ActiveRecord::Migration
  def change
    create_table :russell_lists do |t|
      t.text :syms
      t.date :date

      t.timestamps null: false
    end
  end
end
