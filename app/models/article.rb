class Article < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [:slugged, :history]
  has_many :article_blob_links, dependent: :destroy
  has_many :blobs, through: :article_blob_links, source: :blob
  after_save :sync_blobs_from_content
  # after_update :queue_orphaned_blob_cleanup, if: :saved_change_to_content?
  # before_destroy :queue_all_blob_cleanup
  def should_generate_new_friendly_id?
    title_changed? || slug.blank?
  end
  def referenced_blob_signed_ids
    return [] if content.blank?
    begin
      JSON.parse(content)["blocks"]
        .filter { |block| ["image", "attaches"].include?(block["type"]) }
        .map { |block| block.dig("data", "file", "signed_id") }
        .flatten  # <-- THIS IS THE FIX: Flattens any nested arrays from bad data
        .compact  # Remove any nils
        .uniq     # Get only unique IDs
    rescue JSON::ParserError
      [] # Safely return empty if JSON is bad
    end
  end


  # def referenced_blob_signed_ids
  #   extract_signed_ids_from_content(self.content)
  # end
  # def queue_orphaned_blob_cleanup
  #   # Get the signed_ids from the content *before* the update was saved
  #   old_signed_ids = extract_signed_ids_from_content(self.content_before_last_save)
  #
  #   # Get the signed_ids from the *new* saved content
  #   new_signed_ids = self.referenced_blob_signed_ids
  #
  #   # Calculate the difference: IDs that were in the old content but NOT the new one.
  #   orphaned_signed_ids = old_signed_ids - new_signed_ids
  #
  #   # If there are any orphans, send them to the background job to be purged
  #   if orphaned_signed_ids.any?
  #     BlobCleanupJob.perform_async(orphaned_signed_ids)
  #   end
  # end
  # def queue_all_blob_cleanup
  #   # Get all signed_ids from the content that is about to be destroyed
  #   all_signed_ids = self.referenced_blob_signed_ids
  #
  #   if all_signed_ids.any?
  #     BlobCleanupJob.perform_async(all_signed_ids)
  #   end
  # end
  # def extract_signed_ids_from_content(json_content)
  #   # Return an empty array if there's no content to parse
  #   return [] if json_content.blank?
  #
  #   begin
  #     content_data = JSON.parse(json_content)
  #     signed_ids = []
  #
  #     # Loop over all blocks in the Editor.js data
  #     content_data["blocks"].each do |block|
  #       # Check both block types that handle files
  #       if ["image", "attaches"].include?(block["type"])
  #         # Use .dig for safe nested hash access. This won't crash if keys are missing.
  #         signed_id = block.dig("data", "file", "signed_id")
  #         signed_ids << signed_id if signed_id.present?
  #       end
  #     end
  #
  #     # Return only the unique IDs
  #     signed_ids.uniq
  #   rescue JSON::ParserError
  #     # If the content is invalid JSON, log the error (optional)
  #     # and return an empty array to prevent the app from crashing.
  #     Rails.logger.error "Failed to parse Article content JSON for blob cleanup. Article ID: #{self.id}"
  #     []
  #   end
  # end
  # private
  def sync_blobs_from_content
    # 1. Get blob IDs referenced in the JSON (returns an Array)
    signed_ids_from_json = self.referenced_blob_signed_ids

    # 2. Find all corresponding blobs from that Array
    # current_blob_ids = ActiveStorage::Blob.find_signed(signed_ids_from_json).map(&:id)
    blobs = signed_ids_from_json.map do |signed_id|
      ActiveStorage::Blob.find_signed(signed_id)
    end
    current_blob_ids = blobs.compact.map(&:id)
    # 3. Get blob IDs already linked in the database table
    linked_blob_ids = self.article_blob_links.pluck(:active_storage_blob_id)

    # 4. Delete old links (blobs in DB but NOT in JSON)
    ids_to_unlink = linked_blob_ids - current_blob_ids
    self.article_blob_links.where(active_storage_blob_id: ids_to_unlink).destroy_all

    # 5. Add new links (blobs in JSON but NOT in DB)
    ids_to_link = current_blob_ids - linked_blob_ids

    if ids_to_link.any?
      new_links = ids_to_link.map do |blob_id|
        {
          article_id: self.id,
          active_storage_blob_id: blob_id,
          created_at: Time.current,
          updated_at: Time.current
        }
      end
      # Use insert_all for one fast SQL query
      ArticleBlobLink.insert_all(
        new_links,
        unique_by: [:article_id, :active_storage_blob_id]
      )

      # ArticleBlobLink.insert_all(new_links, unique_by: :index_article_blob_links_on_article_id_and_active_storage_blob_id)
    end
  end
end
