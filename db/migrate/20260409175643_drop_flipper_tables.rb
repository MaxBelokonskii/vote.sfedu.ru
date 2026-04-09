class DropFlipperTables < ActiveRecord::Migration[7.2]
  def up
    drop_table :flipper_gates, if_exists: true
    drop_table :flipper_features, if_exists: true
  end

  def down
    create_table :flipper_features do |t|
      t.string :key, null: false
      t.timestamps
    end
    add_index :flipper_features, :key, unique: true

    create_table :flipper_gates do |t|
      t.string :feature_key, null: false
      t.string :key, null: false
      t.string :value
      t.timestamps
    end
    add_index :flipper_gates, [:feature_key, :key, :value], unique: true
  end
end
