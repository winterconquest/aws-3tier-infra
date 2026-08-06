# cloudwatch.tf
# SNS, CloudWatch metric alerts(ALB, RDS) 정의

locals {
  gib = 1024 * 1024 * 1024
  # 1GiB
}

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy" {
  alarm_name          = "${var.project_name}-alb-unhealthy"
  period              = 60
  evaluation_periods  = 3
  statistic           = "Maximum"
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  treat_missing_data  = "notBreaching" #데이터가 없으면 정상으로 간주
  datapoints_to_alarm = 1

  alarm_description = "ALB 타겟 1개 이상 unhealthy. ASG 자가치유 진행 여부 확인 요망"


  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix             # ALB의 arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix # TG의 arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_healthy" {
  alarm_name          = "${var.project_name}-alb-healthy"
  period              = 60
  evaluation_periods  = 6
  statistic           = "Minimum"
  threshold           = 2
  comparison_operator = "LessThanThreshold"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  treat_missing_data  = "breaching" #데이터가 없으면 ALB나 타겟 그룹 자체에 문제가 생겼다는 의미

  alarm_description = "ALB healthy 타겟이 6분간 2개 미만 지속. ASG 활동 이력과 인스턴스 시작 실패 원인 확인"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix             # ALB의 arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix # TG의 arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

}

resource "aws_cloudwatch_metric_alarm" "rds_freestorage" {
  alarm_name          = "${var.project_name}-rds-freestorage"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  statistic           = "Minimum" # 여유 공간이 줄어드는 걸 보려면
  comparison_operator = "LessThanThreshold"
  threshold           = var.db_allocated_storage * local.gib * var.db_free_storage_threshold_ratio # 계산식
  period              = 600
  evaluation_periods  = 2
  treat_missing_data  = "breaching" # RDS가 죽어서 지표가 끊기면?

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }

}


resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = <<-EOT
{
  "widgets": [
    {
      "type": "text", "x": 0, "y": 0, "width": 24, "height": 1,
      "properties": { "markdown": "## 운영 현황 (실시간)" }
    },
    {
      "type": "alarm", "x": 0, "y": 1, "width": 24, "height": 3,
      "properties": {
        "title": "알람 상태",
        "alarms": [
          "${aws_cloudwatch_metric_alarm.alb_healthy.arn}",
          "${aws_cloudwatch_metric_alarm.alb_unhealthy.arn}",
          "${aws_cloudwatch_metric_alarm.rds_freestorage.arn}"
        ]
      }
    },
    {
      "type": "metric", "x": 0, "y": 4, "width": 6, "height": 6,
      "properties": {
        "title": "ALB 타겟 상태",
        "region": "ap-northeast-2",
        "view": "timeSeries", "stacked": false,
        "period": 60, "stat": "Minimum",
        "yAxis": { "left": { "min": 0 } },
        "metrics": [
          [ "AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", "${aws_lb_target_group.app.arn_suffix}", "LoadBalancer", "${aws_lb.main.arn_suffix}" ],
          [ ".", "UnHealthyHostCount", ".", ".", ".", "." ]
        ]
      }
    },
    {
      "type": "metric", "x": 6, "y": 4, "width": 6, "height": 6,
      "properties": {
        "title": "ALB 5xx / 요청 수",
        "region": "ap-northeast-2",
        "view": "timeSeries", "stacked": false,
        "period": 60, "stat": "Sum",
        "metrics": [
          [ "AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "${aws_lb.main.arn_suffix}", "TargetGroup", "${aws_lb_target_group.app.arn_suffix}" ],
          [ ".", "HTTPCode_ELB_5XX_Count", ".", "${aws_lb.main.arn_suffix}" ],
          [ ".", "RequestCount", ".", ".", { "yAxis": "right" } ]
        ]
      }
    },
    {
      "type": "metric", "x": 12, "y": 4, "width": 6, "height": 6,
      "properties": {
        "title": "ALB 응답 시간",
        "region": "ap-northeast-2",
        "view": "timeSeries", "stacked": false,
        "period": 60,
        "metrics": [
          [ "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${aws_lb.main.arn_suffix}", "TargetGroup", "${aws_lb_target_group.app.arn_suffix}", { "stat": "Average", "label": "평균" } ],
          [ "...", { "stat": "p99", "label": "p99" } ]
        ]
      }
    },
    {
      "type": "metric", "x": 18, "y": 4, "width": 6, "height": 6,
      "properties": {
        "title": "ASG 용량 (Desired vs In-Service)",
        "region": "ap-northeast-2",
        "view": "timeSeries", "stacked": false,
        "period": 60, "stat": "Average",
        "yAxis": { "left": { "min": 0 } },
        "metrics": [
          [ "AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", "${aws_autoscaling_group.app.name}" ],
          [ ".", "GroupInServiceInstances", ".", "." ]
        ]
      }
    },
    {
      "type": "text", "x": 0, "y": 10, "width": 24, "height": 1,
      "properties": { "markdown": "## 자원 사용률" }
    },
    {
      "type": "metric", "x": 0, "y": 11, "width": 8, "height": 6,
      "properties": {
        "title": "EC2 CPU",
        "region": "ap-northeast-2",
        "view": "timeSeries", "stacked": false,
        "period": 300, "stat": "Average",
        "metrics": [
          [ { "expression": "SEARCH('{AWS/EC2,InstanceId} MetricName=\"CPUUtilization\"', 'Average', 300)", "id": "e1" } ]
        ]
      }
    },
    {
      "type": "metric", "x": 8, "y": 11, "width": 8, "height": 6,
      "properties": {
        "title": "RDS CPU / 커넥션",
        "region": "ap-northeast-2",
        "view": "timeSeries", "stacked": false,
        "period": 300, "stat": "Average",
        "metrics": [
          [ "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${aws_db_instance.main.identifier}" ],
          [ ".", "DatabaseConnections", ".", ".", { "yAxis": "right", "stat": "Maximum" } ]
        ]
      }
    },
    {
      "type": "metric", "x": 16, "y": 11, "width": 8, "height": 6,
      "properties": {
        "title": "RDS 여유 스토리지",
        "region": "ap-northeast-2",
        "view": "timeSeries", "stacked": false,
        "period": 600, "stat": "Minimum",
        "yAxis": { "left": { "min": 0 } },
        "metrics": [
          [ "AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "${aws_db_instance.main.identifier}" ]
        ],
        "annotations": {
          "horizontal": [
            { "label": "알람 임계값 (20%)", "value": ${var.db_allocated_storage * 1073741824 * var.db_free_storage_threshold_ratio} }
          ]
        }
      }
    },
    {
      "type": "text", "x": 0, "y": 17, "width": 24, "height": 1,
      "properties": { "markdown": "## 주간 리포팅 (7일 추세)" }
    },
    {
      "type": "metric", "x": 0, "y": 18, "width": 12, "height": 6,
      "properties": {
        "title": "가용 타겟 추세 (7일)",
        "region": "ap-northeast-2",
        "view": "timeSeries", "stacked": false,
        "period": 3600, "stat": "Minimum",
        "start": "-PT168H", "end": "P0D",
        "yAxis": { "left": { "min": 0 } },
        "metrics": [
          [ "AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", "${aws_lb_target_group.app.arn_suffix}", "LoadBalancer", "${aws_lb.main.arn_suffix}" ]
        ]
      }
    },
    {
      "type": "metric", "x": 12, "y": 18, "width": 12, "height": 6,
      "properties": {
        "title": "요청 수 / 오류 추세 (7일)",
        "region": "ap-northeast-2",
        "view": "timeSeries", "stacked": false,
        "period": 3600, "stat": "Sum",
        "start": "-PT168H", "end": "P0D",
        "metrics": [
          [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${aws_lb.main.arn_suffix}" ],
          [ ".", "HTTPCode_ELB_5XX_Count", ".", ".", { "yAxis": "right" } ],
          [ ".", "HTTPCode_Target_5XX_Count", ".", ".", "TargetGroup", "${aws_lb_target_group.app.arn_suffix}", { "yAxis": "right" } ]
        ]
      }
    }
  ]
}
EOT
}