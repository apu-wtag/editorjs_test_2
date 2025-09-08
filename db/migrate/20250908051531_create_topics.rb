class CreateTopics < ActiveRecord::Migration[8.0]
  def change
    create_table :topics do |t|
      t.string :name
      t.string :slug

      t.timestamps
    end
    add_index :topics, :name, unique: true
    add_index :topics, :slug, unique: true
  end
end
