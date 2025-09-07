class ArticleBlobLink < ApplicationRecord
  belongs_to :article
  belongs_to :blob, class_name: "ActiveStorage::Blob", foreign_key: "active_storage_blob_id"
end
