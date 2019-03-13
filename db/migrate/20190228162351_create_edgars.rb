class CreateEdgars < ActiveRecord::Migration
  def change
    create_table :edgars do |t|

      t.timestamps null: false
    end
  end
end
