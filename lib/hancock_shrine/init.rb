require "shrine"
require "shrine/storage/file_system"

Shrine.storages = {
  cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"), # temporary
  store: Shrine::Storage::FileSystem.new("public", prefix: "uploads"),       # permanent
}

# Shrine.plugin :logging, logger: Rails.logger
Shrine.plugin :mongoid if defined?(Mongoid) # or :activerecord 
Shrine.plugin :determine_mime_type
Shrine.plugin :cached_attachment_data # for retaining the cached file across form redisplays
Shrine.plugin :restore_cached_data # re-extract metadata when attaching a cached file
# Shrine.plugin :rack_file # for non-Rails apps
Shrine.plugin :backgrounding


Shrine.plugin :versions
Shrine.plugin :default_version
Shrine.plugin :hancock_location
Shrine.plugin :timestampable
Shrine.plugin :compatibility
