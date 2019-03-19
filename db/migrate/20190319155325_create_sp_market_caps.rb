class CreateSpMarketCaps < ActiveRecord::Migration
  def change
    create_table :sp_market_caps do |t|
      t.date :date
      t.integer :mkt_cap, :limit => 8

      t.timestamps null: false
    end
  end
end
