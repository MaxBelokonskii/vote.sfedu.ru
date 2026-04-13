class AddOriginAndDeletedAtToTeachers < ActiveRecord::Migration[7.2]
  def change
    add_column :teachers, :origin, :string, default: "imported", null: false
    add_column :teachers, :deleted_at, :datetime
    add_index :teachers, :origin
  end
end
