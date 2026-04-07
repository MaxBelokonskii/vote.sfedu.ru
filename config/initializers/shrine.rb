require "shrine"

if Rails.env.test? || Rails.env.development?
  require "shrine/storage/file_system"

  Shrine.storages = {
    cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"),
    store: Shrine::Storage::FileSystem.new("public", prefix: "uploads")
  }
else
  require "shrine/storage/s3"

  s3_options = {
    bucket: ENV.fetch("S3_BUCKET"),
    region: ENV.fetch("S3_REGION", "us-east-1"),
    access_key_id: ENV.fetch("S3_ACCESS_KEY_ID"),
    secret_access_key: ENV.fetch("S3_SECRET_ACCESS_KEY")
  }

  s3_options[:endpoint] = ENV["S3_ENDPOINT"] if ENV["S3_ENDPOINT"].present?
  s3_options[:force_path_style] = true if ENV["S3_ENDPOINT"].present?

  Shrine.storages = {
    cache: Shrine::Storage::S3.new(prefix: "cache", **s3_options),
    store: Shrine::Storage::S3.new(**s3_options)
  }
end

Shrine.plugin :activerecord
Shrine.plugin :cached_attachment_data
Shrine.plugin :restore_cached_data
