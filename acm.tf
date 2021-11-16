resource "aws_acm_certificate" "example" {
  domain_name               = aws_route53_record.example.name
  subject_alternative_names = []
  validation_method         = "DNS"

  lifecycle {                    # 全てのresourceで設定可能
    create_before_destroy = true # リソースを作成してから、リソースを削除する
  }
}
