namespace :cleanup_blob do
  desc "Purge old blobs that are not formally attached OR referenced by any article link."
  task purge_unattached_blobs: :environment do

    puts "Building allow lists from database..."

    # 1. Get ALL blob IDs formally attached to ANY model (e.g., User avatars)
    attached_ids = ActiveStorage::Attachment.distinct.pluck(:blob_id)

    # 2. Get ALL blob IDs referenced in our new Article link table
    referenced_ids = ArticleBlobLink.distinct.pluck(:active_storage_blob_id)

    # 3. Combine them into one master "allow list"
    allow_list_ids = Set.new(attached_ids + referenced_ids)

    puts "Found #{allow_list_ids.count} unique blobs to keep."
    puts "Searching for old blobs to purge (older than 24 hours)..."

    # 4. Find all blobs older than 24 hours that are NOT IN our allow list.
    #    This is ONE efficient SQL query.
    blobs_to_purge = ActiveStorage::Blob
                       .where("created_at <= ?", 24.hours.ago)
                       .where.not(id: allow_list_ids.to_a)

    count = 0
    blobs_to_purge.find_each do |blob|
      blob.purge
      count += 1
      puts "Purged orphan blob: #{blob.filename} (ID: #{blob.id})"
    end

    if count > 0
      puts "Purge complete. Deleted #{count} orphan blob(s)."
    else
      puts "No orphan blobs found. All clean! ✨"
    end
  end
end