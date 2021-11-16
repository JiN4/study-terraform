resource "aws_lb" "example" {
  name                       = "example"
  load_balancer_type         = "application" # アプリケーションロードバランサー指定
  internal                   = false         # インターネット向け
  idle_timeout               = 60            # 秒単位
  enable_deletion_protection = true          # 削除保護

  subnets = [ # 所属するサブネットを指定。異なるAZのサブネットを指定し、クロスゾーン付が分散を実現
    aws_subnet.public_0.id,
    aws_subnet.public_1.id,
  ]

  access_logs {
    bucket  = aws_s3_bucket.alb_log.id # S3バケットの指定 
    enabled = true
  }

  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id,
  ]
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
}



module "http_sg" {
  source      = "./security_group"
  name        = "http-sg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "./security_group"
  name        = "https-sg"
  vpc_id      = aws_vpc.example.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "./security_group"
  name        = "http-redirect-sg"
  vpc_id      = aws_vpc.example.id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}

# HTTPリスナー
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response" # 固定のHTTPレスポンスを応答

    fixed_response {
      content_type = "text/plain"
      message_body = "これは『HTTP』です"
      status_code  = "200"
    }
  }
}

# HTTPSリスナー
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.example.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.example.arn # SSL証明書を指定
  ssl_policy        = "ELBSecurityPolicy-2016-08"     # AWS推奨のセキュリティーポリシー

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは『HTTPS』です"
      status_code  = "200"
    }
  }
}

# ターゲットグループの定義
resource "aws_lb_target_group" "example" {
  name        = "example"
  target_type = "ip" # ECSFargateでは「ip」を指定

  vpc_id               = aws_vpc.example.id # ┓
  port                 = 80                 # ┣ ターゲットグループがipの場合の設定
  protocol             = "HTTP"             # ┛
  deregistration_delay = 300                # ターゲットの登録を解除する前のALBの待機時間

  health_check {
    path                = "/"            # ヘルスチェックで使用するパス
    healthy_threshold   = 5              # 正常判定を行うまでの実行回数
    unhealthy_threshold = 2              # 異常判定を行うまでの実行回数
    timeout             = 5              # タイムアウト時間
    interval            = 30             # 実行間隔
    matcher             = 200            # 正常判定を行うために使用するHTTPステータスコード
    port                = "traffic-port" # ヘルスチェックで使用するポート
    protocol            = "HTTP"         # ヘルスチェック時に使用するプロトコル
  }
  depends_on = [aws_lb.example] # 先にロードバランサーを構築し、その後にターゲットグループを構築するという流れを確立
}

# リスナールールの追加
resource "aws_lb_listener_rule" "example" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100 # ルールの優先順位（デフォルトルールが最も低い）

  action { # フォワード先のターゲットグループを設定
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }

  condition { # 条件指定
    field  = "path-pattern"
    values = ["/*"]
  }
}

