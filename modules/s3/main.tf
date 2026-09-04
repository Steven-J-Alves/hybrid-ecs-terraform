/*===========================
      AWS S3 resources
============================*/

resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name
  # provider      = aws.default
  # acl           = "private"
  force_destroy = true
  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_public_access_block" "s3_access_public" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls   = false
  block_public_policy = false
}