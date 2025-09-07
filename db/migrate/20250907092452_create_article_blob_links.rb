class CreateArticleBlobLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :article_blob_links do |t|
      t.references :article, null: false, foreign_key: true
      t.references :active_storage_blob, null: false, foreign_key: true

      t.timestamps
    end
    add_index :article_blob_links, [:article_id, :active_storage_blob_id], unique: true
  end
end
