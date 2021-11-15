# dataブロック：データの取得のみが発生
# IAMポリシー用：ポリシードキュメント
data "aws_iam_policy_document" "allow_describe_regions" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeRegions"] #リージョン一覧を取得する
    resources = ["*"]
  }
}

# resourceブロック：リソースの作成、更新、削除が行われる（取得も可能）
# IAMポリシー：ポリシードキュメントを保持するリソース
resource "aws_iam_policy" "example" {
  name   = "example"
  policy = data.aws_iam_policy_document.allow_describe_regions.json # jsonとしてデータ取得
}


# IAMロール用：信頼ポリシー（どのサービスに関連付けるか）を宣言
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {                    # 各ドキュメント構成には、1つ以上の statement ブロックが必要
    actions = ["sts:AssumeRole"] # このステートメントが許可または拒否するアクションのリスト
    principals {                 # このステートメントが適用されるリソースを指定するネストされた構成ブロック
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com" # このIAMロールはEC2にのみ関連付けできる
      ]
    }
  }
}

# IAMロール：ロール名と信頼ポリシーを指定
resource "aws_iam_role" "example" {
  name               = "example"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}


# IAMロールにIAMポリシーをアタッチ（IAMロールとIAMポリシーは、関連付けないと機能しないので注意）
resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}


variable "name" {}
variable "policy" {}
variable "identifier" {}

resource "aws_iam_role" "default" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = [var.identifier]
    }
  }
}

resource "aws_iam_policy" "default" {
  name   = var.name
  policy = var.policy
}
resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}
output "iam_role_arn" {
  value = aws_iam_role.default.arn
}
output "iam_role_name" {
  value = aws_iam_role.default.name
}
