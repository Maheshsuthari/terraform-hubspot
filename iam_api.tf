resource "aws_iam_role" "apig-sqs-send-msg-role" {
  name = "${var.app_name}-apig-sqs-send-msg-role"
  tags = "${local.common_tags}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "apig-sqs-send-msg-policy" {
  name        = "${var.app_name}-apig-sqs-send-msg-policy"
  description = "Policy allowing APIG to write to SQS for ${var.app_name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
           "Effect": "Allow",
           "Resource": [
               "*"
           ],
           "Action": [
               "logs:CreateLogGroup",
               "logs:CreateLogStream",
               "logs:PutLogEvents"
           ]
       },
       {
          "Effect": "Allow",
          "Action": "sqs:SendMessage",
          "Resource": "*"
       }
    ]
}
EOF
}

## IAM Role Policies
resource "aws_iam_role_policy_attachment" "apig_sqs_policy_attach" {
  role       = "${aws_iam_role.apig-sqs-send-msg-role.name}"
  policy_arn = "${aws_iam_policy.apig-sqs-send-msg-policy.arn}"
}
