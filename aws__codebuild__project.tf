locals {
  project_name = "hugo_build_project"
}

resource "aws_iam_role" "build_role" {
  name               = "hugo_builder_role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "hugo_builder_role_policy" {
  role = aws_iam_role.build_role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.self.account_id}:log-group:/aws/codebuild/${local.project_name}",
                "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.self.account_id}:log-group:/aws/codebuild/${local.project_name}:*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "${aws_s3_bucket.hugo_bucket.arn}",
                "${aws_s3_bucket.hugo_bucket.arn}/*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:ListBucket"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases",
                "codebuild:BatchPutCodeCoverages"
            ],
            "Resource": [
                "arn:aws:codebuild:${data.aws_region.current.id}:${data.aws_caller_identity.self.account_id}:report-group/${local.project_name}-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudfront:CreateInvalidation"
            ],
            "Resource": [
                "${aws_cloudfront_distribution.hugo_distribution.arn}"
            ]
        }
    ]
}
POLICY
}

resource "aws_codebuild_project" "hugo_build_project" {
  name         = local.project_name
  description  = "Project for building Hugo site."
  service_role = aws_iam_role.build_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type            = "GITHUB"
    location        = var.github_location
    git_clone_depth = 1
    git_submodules_config {
      fetch_submodules = true
    }
    buildspec = <<BUILDSPEC
    version: 0.2

    phases:
      install:
        commands:
          - curl -Ls https://github.com/gohugoio/hugo/releases/download/v0.79.0/hugo_0.79.0_Linux-64bit.tar.gz -o /tmp/hugo.tar.gz
          - tar xf /tmp/hugo.tar.gz -C /tmp
          - mv /tmp/hugo /usr/bin/hugo
          - rm -rf /tmp/hugo*
      build:
        commands:
          - hugo
          - sed -i -e "s/>&lt;/></g" public/index.xml
          - sed -i -e "s/&lt;?xml/<?xml/g" public/index.xml
      post_build:
        commands:
          - aws s3 sync "public/" "s3://${var.hugo_bucket_name}" --exact-timestamps --delete --metadata-directive "REPLACE" --cache-control "public, max-age=31536000" --exclude "index.html" --exclude "post/*" --exclude "tags/*" --exclude "archives/*" --exclude "categories/*" --exclude "about/*" --exclude "projects/*"
          - aws s3 sync "public/" "s3://${var.hugo_bucket_name}" --exact-timestamps --delete --metadata-directive "REPLACE" --cache-control "no-store" --content-type "text/html;charset=UTF-8" --exclude "*" --include "index.html" --include "post/*" --include "tags/*" --include "archives/*" --include "categories/*" --include "about/*"
          - aws s3 cp "public/index.xml" "s3://${var.hugo_bucket_name}/index.xml" --metadata-directive "REPLACE" --content-type "application/rss+xml; charset=UTF-8" --cache-control "public, max-age=1209600"
          - aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.hugo_distribution.id} --paths "/*"
    BUILDSPEC
  }

  source_version = "master"
}

resource "aws_codebuild_webhook" "hugo_build_webhook" {
  project_name = aws_codebuild_project.hugo_build_project.name

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "refs/heads/master"
    }
  }
}
