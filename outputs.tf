// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0


output "knowledge_base_name" {
  value       = module.bedrock_knowledge_base.knowledge_base_name
  description = "Knowledge Base Name"
}

output "knowledge_base_arn" {
  value       = module.bedrock_knowledge_base.knowledge_base_arn
  description = "Knowledge Base Name"
}

output "knowledge_base_id" {
  value       = module.bedrock_knowledge_base.knowledge_base_id
  description = "Knowledge Base ID"
}


output "knowledge_base_data_source_id" {
  value       = module.bedrock_knowledge_base.knowledge_base_data_source_id
  description = "Knowledge Base Data Source ID"
}


output "knowledge_base_bucket" {
  value       = module.knowledge_base_bucket.name
  description = "Knowledge Base Bucket"
}

output "aoss_collection_arn" {
  value       = module.aoss.aoss_collection_arn
  description = "AOSS Collection ARN"
}

output "aoss_collection_name" {
  value       = module.aoss.aoss_collection_name
  description = "AOSS Collection Name"
}

output "aoss_collection_id" {
  value       = module.bedrock_knowledge_base.knowledge_base_id
  description = "AOSS Collection ID"
}


output "agent_actiongroup_lambda_arn" {
  value       = module.bedrock_agent.bedrock_agent_actiongroup_lambda_arn
  description = "Bedrock Agent Action Group Lambda ARN"
}

output "agent_actiongroup_lambda_name" {
  value       = module.bedrock_agent.lambda_function_name
  description = "Bedrock Agent Action Group Lambda Name"
}

output "agent_arn" {
  value       = module.bedrock_agent.bedrock_agent_arn
  description = "Bedrock Agent ARN"
}

output "agent_name" {
  value       = module.bedrock_agent.bedrock_agent_name
  description = "Bedrock Agent Name"
}

output "agent_id" {
  value       = module.bedrock_agent.bedrock_agent_id
  description = "Bedrock Agent ID"
}

output "bedrock_agent_action_group_instruction" {
  value       = module.bedrock_agent.bedrock_agent_action_group_instruction
  description = "Bedrock Agent Action Group Instruction"
}

output "bedrock_agent_instruction" {
  value       = module.bedrock_agent.bedrock_agent_instruction
  description = "Bedrock Agent Instruction"
}


output "ssm_parameter_agent_id" {
  value       = module.bedrock_agent.ssm_parameter_agent_id
  description = "SSM Paramater for Bedrock Agent ID"
}

output "ssm_parameter_agent_alias" {
  value       = module.bedrock_agent.ssm_parameter_agent_alias
  description = "SSM Paramater for Bedrock Agent Alias"
}

output "ssm_parameter_agent_arn" {
  value       = module.bedrock_agent.ssm_parameter_agent_arn
  description = "SSM Paramater for Bedrock Agent ARN"
}

output "ssm_parameter_agent_name" {
  value       = module.bedrock_agent.ssm_parameter_agent_name
  description = "SSM Paramater for Bedrock Agent Name"
}

output "ssm_parameter_agent_instruction" {
  value       = module.bedrock_agent.ssm_parameter_agent_instruction
  description = "SSM Paramater for Bedrock Agent Instruction"
}

output "ssm_parameter_agent_ag_instruction" {
  value       = module.bedrock_agent.ssm_parameter_agent_ag_instruction
  description = "SSM Paramater for Bedrock Agent Action Group Instruction"
}

output "ssm_parameter_knowledge_base_id" {
  value       = module.bedrock_knowledge_base.ssm_parameter_knowledge_base_id
  description = "SSM Paramater for Knowledge Base ID"
}

output "ssm_parameter_knowledge_base_data_source_id" {
  value       = module.bedrock_knowledge_base.ssm_parameter_knowledge_base_data_source_id
  description = "SSM Paramater for Knowledge Base Data Source ID"
}

output "ssm_parameter_lambda_code_sha" {
  value       = module.bedrock_agent.ssm_parameter_agent_ag_lambda_sha
  description = "SSM Paramater for Action Group Lambda SHA"
}

output "lambda_code_sha" {
  value       = module.bedrock_agent.ssm_parameter_agent_ag_lambda_sha
  description = "SSM Paramater for Action Group Lambda SHA"
}


output "ssm_parameter_agent_instruction_history" {
  value       = module.bedrock_agent.ssm_parameter_agent_instruction_history
  description = "SSM Paramater for Agent Instruction History"
}

output "ssm_parameter_kb_instruction_history" {
  value       = module.bedrock_knowledge_base.ssm_parameter_kb_instruction_history
  description = "SSM Paramater for  Knowledge Base Instruction History"
}


output "bedrock_guardrail_id" {
  description = "The ID of the created Bedrock Guardrail"
  value       = var.enable_guardrails ? module.bedrock_guardrail[0].guardrail_id : null
}

output "bedrock_guardrail_arn" {
  description = "The ARN of the created Bedrock Guardrail"
  value       = var.enable_guardrails ? module.bedrock_guardrail[0].guardrail_arn : null
}

output "vpc_endpoint_ids" {
  value = var.enable_endpoints ? module.vpc_endpoints[0].interface_endpoint_ids : null
}

output "bedrock_vpc_endpoint_ids" {
  value = var.enable_endpoints ? module.vpc_endpoints[0].bedrock_interface_endpoint_ids : null
}

output "s3_endpoint_id" {
  value = var.enable_endpoints ? module.vpc_endpoints[0].s3_endpoint_id : null
}

# New outputs for VPC and KMS
output "vpc_id" {
  description = "The ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "vpc_private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "vpc_public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "kms_key_id" {
  description = "The ID of the created KMS key"
  value       = module.kms.key_id
}

output "kms_key_arn" {
  description = "The ARN of the created KMS key"
  value       = module.kms.key_arn
}