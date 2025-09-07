# lib/tasks/cleanup.rake
namespace :cleanup_blob do
  desc "Purge any unattached Active Storage blobs older than 24 hours"
  task purge_unattached_blobs: :environment do

    puts "Searching for unattached blobs older than 24 hours..."

    # This is the magic: ActiveStorage::Blob.unattached finds all blobs
    # that are not linked to any record via an Attachment. This perfectly
    # describes our abandoned-draft uploads.
    # The 24-hour buffer prevents deleting files from a draft that is
    # actively being edited but hasn't been saved yet.
    blobs_to_purge = ActiveStorage::Blob.unattached.where("created_at <= ?", 24.hours.ago)

    count = blobs_to_purge.count

    if count > 0
      puts "Found #{count} unattached blob(s). Purging..."
      # Purge them all
      blobs_to_purge.find_each(&:purge)
      puts "Purge complete."
    else
      puts "No unattached blobs found. All clean! "
    end
  end
end