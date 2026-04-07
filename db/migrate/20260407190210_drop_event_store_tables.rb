class DropEventStoreTables < ActiveRecord::Migration[7.2]
  def up
    drop_table :event_store_events_in_streams, if_exists: true
    drop_table :event_store_events, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
