class BlobCleanupJob
  include Sidekiq::Job

  def perform(signed_ids)
    return if signed_ids.blank?
    signed_ids.each do |signed_id|
      blob = ActiveStorage::Blob.find_signed(signed_id)
      blob.purge if blob.present?
    end
  end
end
