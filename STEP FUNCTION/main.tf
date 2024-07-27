provider "aws" {
  region = "us-west-2" # Cambia la región según sea necesario
}

resource "aws_iam_role" "step_functions_role" {
  name = "StepFunctionsRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })

  inline_policy {
    name = "AllowLambdaInvoke"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Action = [
          "lambda:InvokeFunction"
        ],
        Effect = "Allow",
        Resource = "*"
      }]
    })
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  inline_policy {
    name = "LambdaBasicExecution"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect = "Allow",
        Resource = "*"
      }]
    })
  }
}

resource "aws_s3_object" "lambda_zip" {
  bucket = "stepfunction0109" # Nombre del bucket creado manualmente
  key    = "lambda_function_payload.zip"
  source = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "example_lambda" {
  function_name    = "ExampleLambda"
  s3_bucket        = "stepfunction0109" # Nombre del bucket creado manualmente
  s3_key           = aws_s3_object.lambda_zip.key
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")
}

resource "aws_sfn_state_machine" "example_state_machine" {
  name     = "ExampleStateMachine"
  role_arn = aws_iam_role.step_functions_role.arn
  definition = jsonencode({
    Comment = "A simple AWS Step Functions example with Lambda",
    StartAt = "InvokeLambdaFunction",
    States = {
      InvokeLambdaFunction = {
        Type     = "Task",
        Resource = aws_lambda_function.example_lambda.arn,
        End      = true
      }
    }
  })
}
