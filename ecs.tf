resource "aws_ecs_cluster" "example" {
  name = "example"
}

resource "aws_ecs_task_definition" "example" {
  family                   = "example"
  cpu                      = "256"                                # mamoryとの組み合わせが決まっている
  memory                   = "512"                                # Mib(単位なし) or GB(単位あり)
  network_mode             = "awsvpc"                             # Fargateの場合
  requires_compatibilities = ["FARGATE"]                          # 起動タイプ
  container_definitions    = file("./container_definitions.json") # タスクで実行するコンテナを定義
}


resource "aws_ecs_service" "example" {
  name                              = "example"
  cluster                           = aws_ecs_cluster.example.arn         # ECSクラスタを設定
  task_definition                   = aws_ecs_task_definition.example.arn # タスク定義を設定
  desired_count                     = 2                                   # 維持するタスク数
  launch_type                       = "FARGATE"                           # 起動タイプ
  platform_version                  = "1.3.0"                             # プラットフォームバージョン（デフォルト：LATEST）
  health_check_grace_period_seconds = 60                                  # ヘルスチェック猶予期間（秒単位） デフォルトは０秒のため、タスクの起動に時間がかかる場合、ヘルスチェックに引っかかり、起動と終了が無限ループする可能性があるので注意。

  network_configuration {
    assign_public_ip = false                               # パブリックIPアドレスの割り当ては不要
    security_groups  = [module.nginx_sg.security_group_id] # セキュリティグループの指定

    subnets = [ # サブネットの指定
      aws_subnet.private_0.id,
      aws_subnet.private_1.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.example.arn # ターゲットグループの指定
    container_name   = "example"                       # コンテナ定義のname
    container_port   = 80                              # コンテナ定義のportMappings.containerPort
  }

  lifecycle {
    ignore_changes = [task_definition] # デプロイのたびにタスク定義が更新され、plan時に差分が出る。よってリソースの初回作成時を除き、変更を無視する。
  }
}

module "nginx_sg" {
  source      = "./security_group"
  name        = "nginxsg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = [aws_vpc.example.cidr_block]
}


# IAMロール 
module "ecs_task_execution_role" {
  source     = "./iam_role"
  name       = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json # CloudWatchなど本番環境のため、後に追記
}
