// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "knowledge_base_name" {
  description = "Name of the Bedrock Knowledge Base"
  type        = string
  default     = "bedrock-kb"
}

variable "enable_access_logging" {
  description = "Option to enable Access logging of Knowledge base bucket"
  type        = bool
  default     = true
}

variable "enable_s3_lifecycle_policies" {
  description = "Option to enable Lifecycle policies for Knowledge base bucket Objects"
  type        = bool
  default     = true
}

variable "knowledge_base_model_id" {
  description = "The ID of the foundational model used by the knowledge base."
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "app_name" {
  type    = string
  default = "acme"
}

variable "env_name" {
  type    = string
  default = "dev"
}

variable "app_region" {
  type    = string
  default = "usw2"
}

variable "agent_model_id" {
  description = "The ID of the foundational model used by the agent."
  type        = string
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}

variable "bedrock_agent_invoke_log_bucket" {
  description = "The Bedrock Agent Name"
  type        = string
  default     = "bedrock-agent"
}

variable "agent_name" {
  description = "The Bedrock Agent Name"
  type        = string
  default     = "bedrock-agent"
}

variable "agent_alias_name" {
  description = "The Bedrock Agent Alias Name"
  type        = string
  default     = "bedrock-agent-alias"
}

variable "agent_action_group_name" {
  description = "The Bedrock Agent Action Group Name"
  type        = string
  default     = "bedrock-agent-ag"
}

variable "aoss_collection_name" {
  type        = string
  description = "OpenSearch Collection Name"
  default     = "aoss-collection"
}

variable "aoss_collection_type" {
  type        = string
  description = "OpenSearch Collection Type"
  default     = "VECTORSEARCH"
}

variable "agent_instructions" {
  description = "The type of agent"
  type        = string
  default     = "You are a helpful fitness assistant. You can answer questions related to fitness, diet plans. Use only the tools or knowledge base provided to answer user questions. Choose between the tools or the knowledge base. Do not use both. Do not respond without using a tool or knowledge base. When a user asks to calculate their BMI: 1. Ask for their weight in kilograms. 2. Ask for their height in meters If the user provides values in any other unit, convert it into kilograms for weight and meters for height. Do not make any comments about health status."
}

variable "agent_description" {
  description = "Description of the agent"
  type        = string
  default     = "You are a fitness chatbot"
}

variable "agent_actiongroup_descrption" {
  description = "Description of the action group of the bedrock agent"
  type        = string
  default     = "Use the action group to get the fitness plans, diet plans and historical details"
}

variable "kb_instructions_for_agent" {
  description = "Description of the agent"
  type        = string
  default     = "Use the knowledge base when the user is asking for a definition about a fitness, diet plans. Give a very detailed answer and cite the source."
}

variable "cidr_blocks_sg" {
  type        = list(string)
  description = "VPC/Subnets CIDR blocks to specify in Security Group"
  default     = []
}

variable "code_base_zip" {
  type        = string
  description = "Lambda Code Zip Name in S3 Bucket"
  default     = ""
}

variable "code_base_bucket" {
  type        = string
  description = "Lambda Code Zip Name in S3 Bucket"
  default     = ""
}

# Sample AGent Guardrails values

variable "enable_guardrails" {
  description = "Whether to enable Bedrock guardrails"
  type        = bool
  default     = true
}

variable "guardrail_name" {
  description = "Name of the Bedrock Guardrail"
  type        = string
  default     = "my-bedrock-guardrail"
}

variable "guardrail_blocked_input_messaging" {
  description = "Blocked input messaging for the Bedrock Guardrail"
  type        = string
  default     = "This input is not allowed due to content restrictions."
}

variable "guardrail_blocked_outputs_messaging" {
  description = "Blocked outputs messaging for the Bedrock Guardrail"
  type        = string
  default     = "The generated output was blocked due to content restrictions."
}

variable "guardrail_description" {
  description = "Description of the Bedrock Guardrail"
  type        = string
  default     = "A guardrail for Bedrock to ensure safe and appropriate content"
}

variable "guardrail_content_policy_config" {
  description = "Content policy configuration for the Bedrock Guardrail"
  type        = any
  default     = [
  {
    filters_config = [
      {
        input_strength  = "MEDIUM"
        output_strength = "MEDIUM"
        type            = "HATE"
      },
      {
        input_strength  = "HIGH"
        output_strength = "HIGH"
        type            = "VIOLENCE"
      }
    ]
  }
]
}

variable "guardrail_sensitive_information_policy_config" {
  description = "Sensitive information policy configuration for the Bedrock Guardrail"
  type        = any
  default     = [
  {
    pii_entities_config = [
      {
        action = "BLOCK"
        type   = "NAME"
      },
      {
        action = "BLOCK"
        type   = "EMAIL"
      }
    ],
    regexes_config = [
      {
        action      = "BLOCK"
        description = "Block Social Security Numbers"
        name        = "SSN_Regex"
        pattern     = "^\\d{3}-\\d{2}-\\d{4}$"
      }
    ]
  }
]
}

variable "guardrail_topic_policy_config" {
  description = "Topic policy configuration for the Bedrock Guardrail"
  type        = any
  default     = [
  {
    topics_config = [
      {
        definition = "Any advice or recommendations regarding financial investments or asset allocation."
        examples   = [
          "Where should I invest my money?",
          "What stocks should I buy?"
        ],
        name = "investment_advice",
        type = "DENY"
      }
    ]
  }
]
}

variable "guardrail_word_policy_config" {
  description = "Word policy configuration for the Bedrock Guardrail"
  type        = any
  default     = [
  {
    managed_word_lists_config = [
      {
        type = "PROFANITY"
      }
    ],
    words_config = [
      {
        text = "badword1"
      },
      {
        text = "badword2"
      }
    ]
  }
]
}

variable "enable_endpoints" {
  description = "Whether to enable VPC Endpoints"
  type        = bool
  default     = true
}

variable "enable_frontend" {
  description = "Whether to enable the frontend module"
  type        = bool
  default     = false
}

# Frontend variables
variable "identity_center_instance_arn" {
  description = "ARN of the AWS IAM Identity Center instance"
  type        = string
  default     = ""
}

variable "identity_center_issuer_url" {
  description = "Issuer URL for AWS IAM Identity Center"
  type        = string
  default     = ""
}

variable "identity_center_client_id" {
  description = "Client ID for AWS IAM Identity Center"
  type        = string
  default     = ""
}

variable "identity_center_client_secret" {
  description = "Client secret for AWS IAM Identity Center"
  type        = string
  default     = ""
}

variable "frontend_application_name" {
  description = "Name of the frontend application"
  type        = string
  default     = "bedrock-agent-frontend"
}

variable "enable_custom_domain" {
  description = "Whether to enable custom domain for the frontend"
  type        = bool
  default     = false
}

variable "website_domain_name" {
  description = "Domain name for the website"
  type        = string
  default     = ""
}

variable "api_domain_name" {
  description = "Domain name for the API"
  type        = string
  default     = ""
}

variable "route53_hosted_zone_id" {
  description = "ID of the Route53 hosted zone"
  type        = string
  default     = ""
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
  default     = ""
}

variable "frontend_bucket_name" {
  description = "Name of the S3 bucket for the frontend"
  type        = string
  default     = ""
}

variable "cloudfront_price_class" {
  description = "Price class for CloudFront distribution"
  type        = string
  default     = "PriceClass_100"
}

variable "cloudfront_comment" {
  description = "Comment for CloudFront distribution"
  type        = string
  default     = "Bedrock Agent Frontend"
}

variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "bedrock-agent-api"
}

variable "api_stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "prod"
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "cors_allowed_methods" {
  description = "List of allowed methods for CORS"
  type        = list(string)
  default     = ["GET", "POST", "OPTIONS"]
}

variable "cors_allowed_headers" {
  description = "List of allowed headers for CORS"
  type        = list(string)
  default     = ["Content-Type", "Authorization"]
}

variable "api_lambda_function_name" {
  description = "Name of the API Lambda function"
  type        = string
  default     = "bedrock-agent-api"
}

variable "api_lambda_memory_size" {
  description = "Memory size for the API Lambda function"
  type        = number
  default     = 128
}

variable "api_lambda_timeout" {
  description = "Timeout for the API Lambda function"
  type        = number
  default     = 30
}

variable "api_lambda_runtime" {
  description = "Runtime for the API Lambda function"
  type        = string
  default     = "python3.9"
}

variable "jwt_token_expiration" {
  description = "Expiration time for JWT tokens in seconds"
  type        = number
  default     = 3600
}

variable "api_throttle_burst_limit" {
  description = "Burst limit for API throttling"
  type        = number
  default     = 5
}

variable "api_throttle_rate_limit" {
  description = "Rate limit for API throttling"
  type        = number
  default     = 10
}

variable "enable_api_gateway_logging" {
  description = "Whether to enable API Gateway logging"
  type        = bool
  default     = true
}

variable "api_gateway_log_level" {
  description = "Log level for API Gateway"
  type        = string
  default     = "INFO"
}

variable "enable_xray_tracing" {
  description = "Whether to enable X-Ray tracing"
  type        = bool
  default     = true
}

variable "api_lambda_log_retention_days" {
  description = "Number of days to retain API Lambda logs"
  type        = number
  default     = 30
}

variable "api_gateway_log_retention_days" {
  description = "Number of days to retain API Gateway logs"
  type        = number
  default     = 30
}