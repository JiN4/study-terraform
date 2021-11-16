# VPCを作成
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16" # IPv4アドレスの範囲を指定
  enable_dns_support   = true          # AWSのDNSサーバーによる名前解決を有効化
  enable_dns_hostnames = true          # VPC内のリソースにパブリックDNSホスト名を自動的に割り当てる

  tags = {
    Name = "example"
  }
}

# Internet Gatewayの定義
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

#--public------------------------------------------------

# VPCをさらに分割し、パブリックサブネットを作成する
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.0.0/24"     # IPv4アドレスの範囲を指定
  map_public_ip_on_launch = true              # 起動したインスタンスにパブリックIPアドレスを自動的に割り当てる
  availability_zone       = "ap-northeast-1a" # サブネットを作成するアベイラビリティゾーンを指定
}

# ルートテーブルの定義
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
}

# ルートの定義
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.example.id
  destination_cidr_block = "0.0.0.0/0"
}

# サブネットとルートテーブルの関連づけ
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


#--private------------------------------------------------

# サブネットの作成
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.64.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false # プライベートなためパブリックIPアドレスの割り当ては不要
}

# ルートテーブルの定義
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.example.id
}

# サブネットとルートテーブルの関連づけ
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Elastic IP Addressの定義
resource "aws_eip" "nat_gateway" {
  vpc        = true
  depends_on = [aws_internet_gateway.example] # 明示的にInternet Gatewayとの依存関係を記すことで、先にInternet Gatewayを構築し、その後にEIPを構築するという流れを確立
}

# NAT Gatewayの定義
resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.example] # 明示的にInternet Gatewayとの依存関係を記すことで、先にInternet Gatewayを構築し、その後にNAT Gatewayを構築するという流れを確立
}

# ルートテーブルの定義
resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.example.id # NAT Gatewayを指定
  destination_cidr_block = "0.0.0.0/0"
}
