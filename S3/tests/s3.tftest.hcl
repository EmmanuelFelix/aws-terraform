# tests/s3.tftest.hcl

# 1. Test that the backup bucket has versioning enabled
run "verify_backup_versioning" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.backups.versioning_configuration[0].status == "Enabled"
    error_message = "Backup bucket must have versioning enabled for data safety."
  }
}

# 2. Test that the logs bucket is strictly private
run "verify_logs_privacy" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.logs.restrict_public_buckets == true
    error_message = "Log bucket must restrict public buckets."
  }
}

# 3. Test that the static site has an index document configured
run "verify_website_config" {
  command = plan

  assert {
    condition     = aws_s3_bucket_website_configuration.static_assets.index_document[0].suffix == "index.html"
    error_message = "Static asset bucket must have an index.html configured."
  }
}