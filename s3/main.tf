# プライベートバケット
resource "aws_s3_bucket" "private" {
  bucket = "private-pragmatic-terraform"
  versioning {
    enabled = true # バージョン管理の有効化
  }
  server_side_encryption_configuration { // 暗号化
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# ブロックパブリックアクセス
resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.private.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# パブリックバケット
resource "aws_s3_bucket" "public" {
  bucket = "public-pragmatic-terraform"
  acl    = "public-read" # インターネットからの読み込みを許可(default：private)
  cors_rule {
    allowed_origins = ["https://example.com"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "alb_log" {
  bucket = "alb-log-pragmatic-terraform"
  lifecycle_rule {
    enabled = true
    expiration { # オブジェクトの有効期限の期間を指定
      days = "180"
    }
  }
}


resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

# ALBからS3への書き込みを行う場合
data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]
    principals { # AWSが管理しているアカウントを指定(東京リージョンのALBのアカウントID)
      type        = "AWS"
      identifiers = ["582318560864"]
    }
  }
}

resource "aws_s3_bucket" "force_destroy" {
  bucket        = "force-destroy-pragmatic-terraform"
  force_destroy = true
}
