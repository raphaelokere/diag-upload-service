resource "aws_s3_bucket" "bucket_artifacts" {
  bucket = "raph-hidden-artifacts"
  acl    = "private"
}