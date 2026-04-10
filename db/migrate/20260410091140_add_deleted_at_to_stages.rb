class AddDeletedAtToStages < ActiveRecord::Migration[7.2]
  def change
    add_column :stages, :deleted_at, :datetime
  end
end
