/*=============================
    AWS ECS Cluster
===============================*/
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = var.container_insights
  }
}

/*=============================
    AWS ECS CP Cluster
===============================*/
resource "aws_ecs_cluster_capacity_providers" "cluster" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.capacity_provider_ec2.name, "FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.capacity_provider_ec2.name
    base              = var.base_capacity
    weight            = var.default_weight
  }
}

/*=============================
    ECS Capacity Provider
===============================*/
resource "aws_ecs_capacity_provider" "capacity_provider_ec2" {
  name = "${aws_ecs_cluster.ecs_cluster.name}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.autoscaling_group_ec2.arn
    managed_termination_protection = var.termination_protection

    managed_scaling {
      maximum_scaling_step_size = var.maximum_scaling_step_size
      minimum_scaling_step_size = var.minimum_scaling_step_size
      status                    = var.managed_scaling_status
      target_capacity           = var.target_capacity
    }
  }
}

/*=============================
    Launch Template
===============================*/
resource "aws_launch_template" "launch_template_ec2" {
  name          = "${aws_ecs_cluster.ecs_cluster.name}-lt"
  image_id      = var.image_id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_node.arn
  }

  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config;
    EOF
  )

  key_name = var.key_name

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip # New variable for public IP association
    delete_on_termination       = true
    security_groups             = var.security_groups
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = var.name
    })
  }

  # Tag specification for the EBS volume
  tag_specifications {
    resource_type = "volume"
    tags          = var.tags
  }

  # Tag specification for network interfaces (optional)
  tag_specifications {
    resource_type = "network-interface"
    tags          = var.tags
  }

  # Tag specification for Spot Instance requests
  tag_specifications {
    resource_type = "spot-instances-request"
    tags          = var.tags
  }
}

/*=============================
    Auto Scaling Group
===============================*/
resource "aws_autoscaling_group" "autoscaling_group_ec2" {
  name                = "${var.name}-asg"
  min_size            = var.min_size         # New variable for min size
  max_size            = var.max_size         # New variable for max size
  desired_capacity    = var.desired_capacity # New variable for desired capacity
  vpc_zone_identifier = var.vpc_zone_identifier
  capacity_rebalance  = true

  default_cooldown          = var.default_cooldown
  health_check_type         = "EC2"
  health_check_grace_period = var.health_check_grace_period

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = var.on_demand_base_capacity                  # New variable
      on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base_capacity # New variable
      spot_allocation_strategy                 = var.spot_allocation_strategy                 # New variable
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.launch_template_ec2.id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = var.override_instance_types
        content {
          instance_type = override.value
        }
      }
    }
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_schedule" "scale_down_schedule" {
  count = var.enable_scaling_schedule ? 1 : 0

  scheduled_action_name  = "${var.name}-scale-down"
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group_ec2.name
  desired_capacity       = 0
  min_size               = 0
  max_size               = 0
  start_time             = var.scale_down_start_time
  recurrence             = var.scale_down_recurrence
}

resource "aws_autoscaling_schedule" "scale_up_schedule" {
  count                  = var.enable_scaling_schedule ? 1 : 0
  scheduled_action_name  = "${var.name}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group_ec2.name
  desired_capacity       = var.desired_capacity
  min_size               = var.min_size
  max_size               = var.max_size
  start_time             = var.scale_up_start_time
  recurrence             = var.scale_up_recurrence
}

/*=============================
    AWS ECS Node Role
===============================*/
data "aws_iam_policy_document" "ecs_node_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_node_role" {
  name_prefix        = var.node_role_name_prefix
  assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = var.ecs_node_policy_arn
}

resource "aws_iam_instance_profile" "ecs_node" {
  name_prefix = "${var.name}-ecs-node-profile"
  path        = var.instance_profile_path
  role        = aws_iam_role.ecs_node_role.name
}
