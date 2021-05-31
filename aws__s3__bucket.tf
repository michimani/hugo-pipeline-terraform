resource "aws_s3_bucket" "hugo_bucket" {
  bucket = var.hugo_bucket_name
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.hugo_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.hugo_origin_access.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "hugo_bucket_policy" {
  bucket = aws_s3_bucket.hugo_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}
