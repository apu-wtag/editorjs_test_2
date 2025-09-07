class Article < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [:slugged, :history]
  after_update :queue_orphaned_blob_cleanup, if: :saved_change_to_content?
  before_destroy :queue_all_blob_cleanup
  def should_generate_new_friendly_id?
    title_changed? || slug.blank?
  end
  def referenced_blob_signed_ids
    extract_signed_ids_from_content(self.content)
  end
  def queue_orphaned_blob_cleanup
    # Get the signed_ids from the content *before* the update was saved
    old_signed_ids = extract_signed_ids_from_content(self.content_before_last_save)

    # Get the signed_ids from the *new* saved content
    new_signed_ids = self.referenced_blob_signed_ids

    # Calculate the difference: IDs that were in the old content but NOT the new one.
    orphaned_signed_ids = old_signed_ids - new_signed_ids

    # If there are any orphans, send them to the background job to be purged
    if orphaned_signed_ids.any?
      BlobCleanupJob.perform_async(orphaned_signed_ids)
    end
  end
  def queue_all_blob_cleanup
    # Get all signed_ids from the content that is about to be destroyed
    all_signed_ids = self.referenced_blob_signed_ids

    if all_signed_ids.any?
      BlobCleanupJob.perform_async(all_signed_ids)
    end
  end
  def extract_signed_ids_from_content(json_content)
    # Return an empty array if there's no content to parse
    return [] if json_content.blank?

    begin
      content_data = JSON.parse(json_content)
      signed_ids = []

      # Loop over all blocks in the Editor.js data
      content_data["blocks"].each do |block|
        # Check both block types that handle files
        if ["image", "attaches"].include?(block["type"])
          # Use .dig for safe nested hash access. This won't crash if keys are missing.
          signed_id = block.dig("data", "file", "signed_id")
          signed_ids << signed_id if signed_id.present?
        end
      end

      # Return only the unique IDs
      signed_ids.uniq
    rescue JSON::ParserError
      # If the content is invalid JSON, log the error (optional)
      # and return an empty array to prevent the app from crashing.
      Rails.logger.error "Failed to parse Article content JSON for blob cleanup. Article ID: #{self.id}"
      []
    end
  end
end
