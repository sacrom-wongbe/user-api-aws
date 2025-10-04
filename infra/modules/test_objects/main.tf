resource "aws_s3_bucket" "test_bucket" {
  bucket = "test-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "Test Bucket"
    Environment = "test"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 2
}