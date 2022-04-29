resource "aws_lambda_function" "lambda-sync" {
  filename = "${data.archive_file.lambda_zip_file.output_path}"
  function_name = "${var.service}-${var.environment}"
  description   = "DDB > lambda > ES"
  role          = "${aws_iam_role.lambda_assume_role.arn}"
  handler       = "handler.handler"

  runtime = "python3.8"
  environment {
    variables = {
      ES_HOST = "${var.es_host}"
      ES_REGION = "${var.region}"
    }
  }
  
  vpc_config {
    security_group_ids = ["${aws_security_group.sync_sg.id}"]
    subnet_ids = ["${random_shuffle.sync_subnet_ids.result}"]
  }

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${data.archive_file.lambda_zip_file.output_base64sha256}"

  tags {
    CostCentre = "${var.cost_centre}"
    Environment = "${var.environment}"
    EnvironmentZone = "${var.environment_zone}"
    Name = "lambda-${var.service}-${var.environment}"
    Owner = "${var.owner}"
    Region = "${var.region}"
    Role = "${var.role}"
    Service = "${var.service}"
    CreatedBy = "${var.created_by}"
    Team = "${var.team}"
  }
}

resource "aws_lambda_event_source_mapping" "stream_function_event_trigger" {
  event_source_arn  = "${var.stream_arn}"
  function_name     = "${aws_lambda_function.lambda-sync.arn}"
  starting_position = "LATEST"
}

resource "aws_security_group" "sync_sg" {
  name        = "sges-${var.service}-${var.environment}"
  description = "${var.service}-${var.environment} security group"
  vpc_id      = "${data.aws_vpc.current.id}"

  # Add a map of standards tags for this resource to a map of tags passed into the module:
  tags = "${merge(map(
    "Name", "sges-${var.service}-${var.environment}"),
    local.all_tags
  )}"
}

resource "aws_security_group_rule" "sync_egress_all" {
  type              = "egress"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = [ "0.0.0.0/0" ]
  security_group_id = "${aws_security_group.sync_sg.id}"
}

# this allows network access to the ES cluster to all subnets AZ's specified in var.es_azs
resource "aws_security_group_rule" "sync_ingress" {
  count             = "${length(data.aws_subnet.sync_subnets.*.cidr_block)}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [ "${element(data.aws_subnet.sync_subnets.*.cidr_block, count.index)}" ]
  security_group_id = "${aws_security_group.sync_sg.id}"
}

resource "random_shuffle" "sync_subnet_ids" {
  input = ["${data.aws_subnet.sync_subnets.*.id}"]
  result_count = "${var.sync_subnet_ids[0] == "" && !var.sync_multi_az ? 1 : 2}"
}
