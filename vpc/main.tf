# VPCを作成
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16" # IPv4アドレスの範囲を指定
  enable_dns_support   = true          # AWSのDNSサーバーによる名前解決を有効化
  enable_dns_hostnames = true          # VPC内のリソースにパブリックDNSホスト名を自動的に割り当てる

  tags = {
    Name = "example"
  }
}

# VPCをさらに分割し、サブネットを作成する
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.0.0/24"     # IPv4アドレスの範囲を指定
  map_public_ip_on_launch = true              #起動したインスタンスにパブリックIPアドレスを自動的に割り当てる
  availability_zone       = "ap-northeast-1a" # サブネットを作成するアベイラビリティゾーンを指定
}
