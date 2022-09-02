resource "aws_s3_bucket" "hugo_bucket" {
  bucket = var.hugo_bucket_name
}

resource "aws_s3_bucket_policy" "hugo_bucket_policy" {
  bucket = aws_s3_bucket.hugo_bucket.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "OriginAccessControlStatement",
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "cloudfront.amazonaws.com"
          },
          "Action" : "s3:GetObject",
          "Resource" : "${aws_s3_bucket.hugo_bucket.arn}/*",
          "Condition" : {
            "StringEquals" : {
              "AWS:SourceArn" : "${aws_cloudfront_distribution.hugo_distribution.arn}"
            }
          }
        }
      ]
    }
  )
}
