BUNDLE_PATH = "/usr/local/lib/ruby/gems/3.4.0/bin/bundle"

job_type :rake, "cd :path && #{BUNDLE_PATH} exec rake :task --silent :output"

set :output, "log/cron.log"  # where output/errors go
set :environment, "development" # or production

every 1.day, at: "3:00 AM" do
  rake "cleanup_blob:purge_unattached_blobs"
end
