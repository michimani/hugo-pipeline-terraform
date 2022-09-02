resource "aws_cloudfront_origin_access_control" "hugo_oac" {
  name                              = "hugo-oring-access-control"
  description                       = "Origin Access Control for Hugo blog"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
