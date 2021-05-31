resource "aws_cloudfront_origin_access_identity" "hugo_origin_access" {
  comment = "Origin Access Identity for Hugo Bucket"
}
