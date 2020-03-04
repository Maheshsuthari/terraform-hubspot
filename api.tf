// ******************** API GATEWAY SETUP ******************** //
resource "aws_api_gateway_rest_api" "myapp_apig" {
  name = "${var.app_name}-apig"
}

resource "aws_api_gateway_resource" "webhook_resource" {
  path_part   = "webhook"
  parent_id   = "${aws_api_gateway_rest_api.myapp_apig.root_resource_id}"
  rest_api_id = "${aws_api_gateway_rest_api.myapp_apig.id}"
}

resource "aws_api_gateway_resource" "webhook_shopify_resource" {
  path_part   = "shopify"
  parent_id   = "${aws_api_gateway_resource.webhook_resource.id}"
  rest_api_id = "${aws_api_gateway_rest_api.myapp_apig.id}"
}

resource "aws_api_gateway_method" "webhook_shopify_post_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.myapp_apig.id}"
  resource_id   = "${aws_api_gateway_resource.webhook_shopify_resource.id}"
  http_method   = "POST"
  authorization = "NONE"
}


resource "aws_api_gateway_method_settings" "webhook_shopify_post_method_settings" {
  rest_api_id = "${aws_api_gateway_rest_api.myapp_apig.id}"
  stage_name  = "${aws_api_gateway_stage.myapp_deployment_stage.stage_name}"
  method_path = "${aws_api_gateway_resource.webhook_shopify_resource.path_part}/${aws_api_gateway_method.webhook_shopify_post_method.http_method}"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

resource "aws_api_gateway_integration" "webhook_shopify_post_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.myapp_apig.id}"
  resource_id             = "${aws_api_gateway_resource.webhook_shopify_resource.id}"
  http_method             = "${aws_api_gateway_method.webhook_shopify_post_method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS"
  credentials             = "${aws_iam_role.apig-sqs-send-msg-role.arn}"
  uri                     = "arn:aws:apigateway:${var.region}:sqs:path/${data.aws_caller_identity.current.account_id}/SomeQueue"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = <<EOF
Action=SendMessage&MessageGroupId=1&MessageBody=
{
  "body" : $input.json('$'),
  "rawbody" : "$util.base64Encode($input.body)",
  "headers": {
    #foreach($header in $input.params().header.keySet())
    "$header": "$util.escapeJavaScript($input.params().header.get($header))" #if($foreach.hasNext),#end
    #end
  },
  "method": "$context.httpMethod",
  "params": {
    #foreach($param in $input.params().path.keySet())
    "$param": "$util.escapeJavaScript($input.params().path.get($param))" #if($foreach.hasNext),#end
    #end
  },
  "query": {
    #foreach($queryParam in $input.params().querystring.keySet())
    "$queryParam": "$util.escapeJavaScript($input.params().querystring.get($queryParam))" #if($foreach.hasNext),#end
    #end
  }
}
EOF
  }
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
}


resource "aws_api_gateway_method_response" "webhook_shopify_post_method_response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.myapp_apig.id}"
  resource_id = "${aws_api_gateway_resource.webhook_shopify_resource.id}"
  http_method = "${aws_api_gateway_method.webhook_shopify_post_method.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "webhook_shopify_post_integration_response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.myapp_apig.id}"
  resource_id = "${aws_api_gateway_resource.webhook_shopify_resource.id}"
  http_method = "${aws_api_gateway_method.webhook_shopify_post_method.http_method}"
  status_code = "${aws_api_gateway_method_response.webhook_shopify_post_method_response_200.status_code}"
}
resource "aws_cloudwatch_log_group" "webhook_shopify_log_group" {
  name              = "APIG-Execution-Logs_${aws_api_gateway_rest_api.myapp_apig.name}"
  retention_in_days = 30
}

## Setup the stages and deploy to the stage when terraform is run.
resource "aws_api_gateway_stage" "myapp_deployment_stage" {
  stage_name    = "dev-temp" // This a hack to fix the API being auto deployed.
  rest_api_id   = "${aws_api_gateway_rest_api.myapp_apig.id}"
  deployment_id = "${aws_api_gateway_deployment.myapp_deployment.id}"

}

resource "aws_api_gateway_deployment" "myapp_deployment" {
  rest_api_id     = "${aws_api_gateway_rest_api.myapp_apig.id}"
  stage_name      = "dev"
}
