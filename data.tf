data "archive_file" "lambda_zip_file" {
  output_path = "${path.module}/lambda_zip/lambda.zip"
  source_dir  = "${path.module}/lambda"
  excludes    = ["__init__.py", "*.pyc"]
  type        = "zip"
}

data "aws_subnet" "sync_subnets" {
  count = "${length(var.sync_azs)}"

  filter {
    name = "tag:Name"
    values = ["sn-${var.subnets_name}-${var.subnet_env}-${element(var.sync_azs, count.index)}"]
  }
}
