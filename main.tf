// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_region" "current" {}

locals {
  availability_zones = ["${data.aws_region.current.name}a", "${data.aws_region.current.name}b"]
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr           = "10.0.0.0/16"
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
  availability_zones = local.availability_zones
  app_name           = var.app_name
  env_name           = var.env_name
}

module "kms" {
  source                 = "./modules/kms"
  app_name               = var.app_name
  env_name               = var.env_name
  deletion_window_in_days = 30
}

module "knowledge_base_bucket" {
  source                                = "./modules/s3"
  kb_bucket_name_prefix                 = "kb-${var.app_region}-${var.env_name}"
  log_bucket_name_prefix                = "kb-accesslog-${var.app_region}-${var.env_name}"
  kb_bucket_log_bucket_directory_prefix = "log-${var.app_region}-${var.env_name}"
  kms_key_id                            = module.kms.key_arn
  enable_access_logging                 = var.enable_access_logging
  enable_s3_lifecycle_policies          = var.enable_s3_lifecycle_policies
  vpc_id                                = module.vpc.vpc_id
}

module "roles" {
  source                              = "./modules/roles"
  agent_model_id                      = var.agent_model_id
  knowledge_base_model_id             = var.knowledge_base_model_id
  knowledge_base_bucket_arn           = module.knowledge_base_bucket.arn
  knowledge_base_arn                  = module.bedrock_knowledge_base.knowledge_base_arn
  bedrock_agent_invoke_log_group_name = "agent-invoke-log-${var.agent_name}-${var.app_region}-${var.env_name}"
  kms_key_id                          = module.kms.key_arn
  env_name                            = var.env_name
  app_name                            = var.app_name
}

module "aoss" {
  source                  = "./modules/aoss"
  aoss_collection_name    = "${var.aoss_collection_name}-${var.app_region}-${var.env_name}"
  aoss_collection_type    = var.aoss_collection_type
  knowledge_base_role_arn = module.roles.knowledge_base_role_arn
  vpc_id                  = module.vpc.vpc_id
  vpc_subnet_ids          = module.vpc.private_subnet_ids
  kms_key_id              = module.kms.key_arn
  env_name                = var.env_name
  app_name                = var.app_name
}

module "bedrock_knowledge_base" {
  source                    = "./modules/bedrock/knowledge_base"
  aoss_collection_arn       = module.aoss.aoss_collection_arn
  knowledge_base_role_arn   = module.roles.knowledge_base_role_arn
  knowledge_base_role       = module.roles.knowledge_base_role_name
  knowledge_base_bucket_arn = module.knowledge_base_bucket.arn
  knowledge_base_model_id   = var.knowledge_base_model_id
  knowledge_base_name       = "${var.knowledge_base_name}-${var.app_region}-${var.env_name}"
  agent_model_id            = var.agent_model_id
  kms_key_id                = module.kms.key_arn
  env_name                  = var.env_name
  app_name                  = var.app_name
}

module "bedrock_agent" {
  source                              = "./modules/bedrock/agent"
  agent_name                          = "${var.agent_name}-${var.app_region}-${var.env_name}"
  agent_model_id                      = var.agent_model_id
  agent_role_arn                      = module.roles.bedrock_agent_role_arn
  agent_lambda_role_arn               = module.roles.bedrock_agent_lambda_role_arn
  agent_alias_name                    = "${var.agent_alias_name}-${var.app_region}-${var.env_name}"
  agent_action_group_name             = "${var.agent_action_group_name}-${var.app_region}-${var.env_name}"
  agent_instructions                  = var.agent_instructions
  agent_actiongroup_descrption        = var.agent_actiongroup_descrption
  agent_description                   = var.agent_description
  knowledge_base_arn                  = module.bedrock_knowledge_base.knowledge_base_arn
  knowledge_base_id                   = module.bedrock_knowledge_base.knowledge_base_id
  knowledge_base_bucket               = module.knowledge_base_bucket.name
  bedrock_agent_invoke_log_group_name = "agent-invoke-log-${var.agent_name}-${var.app_region}-${var.env_name}"
  bedrock_agent_invoke_log_group_arn  = module.roles.bedrock_agent_invoke_log_group_role_arn
  code_base_bucket                    = var.code_base_bucket
  code_base_zip                       = var.code_base_zip
  kb_instructions_for_agent           = var.kb_instructions_for_agent
  vpc_id                              = module.vpc.vpc_id
  cidr_blocks_sg                      = module.vpc.private_subnet_cidr_blocks
  vpc_subnet_ids                      = module.vpc.private_subnet_ids
  kms_key_id                          = module.kms.key_arn
  env_name                            = var.env_name
  app_name                            = var.app_name
}

module "bedrock_guardrail" {
  count                               = var.enable_guardrails ? 1 : 0
  source                              = "./modules/bedrock/agent-guardrails"
  name                                = var.guardrail_name
  blocked_input_messaging             = var.guardrail_blocked_input_messaging
  blocked_outputs_messaging           = var.guardrail_blocked_outputs_messaging
  description                         = var.guardrail_description
  content_policy_config               = var.guardrail_content_policy_config
  sensitive_information_policy_config = var.guardrail_sensitive_information_policy_config
  topic_policy_config                 = var.guardrail_topic_policy_config
  word_policy_config                  = var.guardrail_word_policy_config
  kms_key_id                          = module.kms.key_arn
}

module "vpc_endpoints" {
  source                                = "./modules/endpoints"
  count                                 = var.enable_endpoints ? 1 : 0
  vpc_id                                = module.vpc.vpc_id
  cidr_blocks_sg                        = module.vpc.private_subnet_cidr_blocks
  vpc_subnet_ids                        = module.vpc.private_subnet_ids
  lambda_security_group_id              = module.bedrock_agent.lambda_security_group_id
  enable_cloudwatch_endpoint            = true
  enable_kms_endpoint                   = true
  enable_ssm_endpoint                   = true
  enable_s3_endpoint                    = true
  enable_sqs_endpoint                   = true
  enable_bedrock_endpoint               = true
  enable_bedrock_runtime_endpoint       = true
  enable_bedrock_agent_endpoint         = true
  enable_bedrock_agent_runtime_endpoint = true
  env_name                              = var.env_name
  app_name                              = var.app_name
}

# Optional
module "agent_update_lifecycle" {
  source                                  = "./modules/bedrock/agent-lifecycle"
  code_base_bucket                        = var.code_base_bucket
  ssm_parameter_agent_name                = module.bedrock_agent.ssm_parameter_agent_name
  ssm_parameter_agent_id                  = module.bedrock_agent.ssm_parameter_agent_id
  ssm_parameter_agent_alias               = module.bedrock_agent.ssm_parameter_agent_alias
  ssm_parameter_agent_instruction         = module.bedrock_agent.ssm_parameter_agent_instruction
  ssm_parameter_agent_ag_instruction      = module.bedrock_agent.ssm_parameter_agent_ag_instruction
  ssm_parameter_knowledge_base_id         = module.bedrock_knowledge_base.ssm_parameter_knowledge_base_id
  ssm_parameter_lambda_code_sha           = module.bedrock_agent.ssm_parameter_agent_ag_lambda_sha
  ssm_parameter_agent_instruction_history = module.bedrock_agent.ssm_parameter_agent_instruction_history
  ssm_parameter_kb_instruction_history    = module.bedrock_knowledge_base.ssm_parameter_kb_instruction_history
  lambda_function_name                    = module.bedrock_agent.lambda_function_name
  depends_on                              = [module.knowledge_base_bucket, module.roles, module.aoss, module.bedrock_knowledge_base, module.bedrock_agent, module.bedrock_guardrail[0]]
}

# Frontend module (conditional)
module "frontend" {
  count                           = var.enable_frontend ? 1 : 0
  source                          = "./modules/frontend"
  app_name                        = var.app_name
  env_name                        = var.env_name
  app_region                      = var.app_region
  kms_key_id                      = module.kms.key_arn
  
  # Identity Center Configuration
  identity_center_instance_arn    = var.identity_center_instance_arn
  identity_center_issuer_url      = var.identity_center_issuer_url
  identity_center_client_id       = var.identity_center_client_id
  identity_center_client_secret   = var.identity_center_client_secret
  frontend_application_name       = var.frontend_application_name
  
  # Domain Configuration
  enable_custom_domain            = var.enable_custom_domain
  website_domain_name             = var.website_domain_name
  api_domain_name                 = var.api_domain_name
  route53_hosted_zone_id          = var.route53_hosted_zone_id
  ssl_certificate_arn             = var.ssl_certificate_arn
  
  # S3 Configuration
  frontend_bucket_name            = var.frontend_bucket_name
  
  # CloudFront Configuration
  cloudfront_price_class          = var.cloudfront_price_class
  cloudfront_comment              = var.cloudfront_comment
  
  # API Gateway Configuration
  api_gateway_name                = var.api_gateway_name
  api_stage_name                  = var.api_stage_name
  
  # CORS Configuration
  cors_allowed_origins            = var.cors_allowed_origins
  cors_allowed_methods            = var.cors_allowed_methods
  cors_allowed_headers            = var.cors_allowed_headers
  
  # Lambda Configuration
  api_lambda_function_name        = var.api_lambda_function_name
  api_lambda_memory_size          = var.api_lambda_memory_size
  api_lambda_timeout              = var.api_lambda_timeout
  api_lambda_runtime              = var.api_lambda_runtime
  
  # Security Configuration
  jwt_token_expiration            = var.jwt_token_expiration
  api_throttle_burst_limit        = var.api_throttle_burst_limit
  api_throttle_rate_limit         = var.api_throttle_rate_limit
  
  # Monitoring Configuration
  enable_api_gateway_logging      = var.enable_api_gateway_logging
  api_gateway_log_level           = var.api_gateway_log_level
  enable_xray_tracing             = var.enable_xray_tracing
  api_lambda_log_retention_days   = var.api_lambda_log_retention_days
  api_gateway_log_retention_days  = var.api_gateway_log_retention_days
  
  # Bedrock Agent Integration
  bedrock_agent_id                = module.bedrock_agent.agent_id
  bedrock_agent_alias_id          = module.bedrock_agent.agent_alias_id
  
  # VPC Configuration
  vpc_id                          = module.vpc.vpc_id
  vpc_subnet_ids                  = module.vpc.private_subnet_ids
  cidr_blocks_sg                  = module.vpc.private_subnet_cidr_blocks
  
  depends_on = [
    module.bedrock_agent,
    module.bedrock_knowledge_base
  ]
}