// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# Sample Values, modify accordingly

knowledge_base_name                 = "bedrock-kb"
enable_access_logging               = true
enable_s3_lifecycle_policies        = true
enable_endpoints                    = true
knowledge_base_model_id             = "amazon.titan-embed-text-v2:0"
app_name                            = "acme"
env_name                            = "prod"
app_region                          = "usw2"
agent_model_id                      = "anthropic.claude-3-haiku-20240307-v1:0"
bedrock_agent_invoke_log_bucket     = "bedrock-agent-logs"
agent_name                          = "bedrock-agent"
agent_alias_name                    = "bedrock-agent-alias"
agent_action_group_name             = "bedrock-agent-ag"
aoss_collection_name                = "aoss-collection"
aoss_collection_type                = "VECTORSEARCH"
agent_instructions                  = <<-EOT
You are an advanced AI assistant with access to a knowledge base. Your primary goal is to provide accurate, comprehensive, and helpful responses based on the information available in your knowledge base.

GUIDELINES:
1. ALWAYS use the knowledge base when answering questions. Search for relevant information before responding.
2. Provide detailed, thorough answers that fully address the user's query.
3. When citing information from the knowledge base, mention the source clearly.
4. If the knowledge base contains multiple relevant pieces of information, synthesize them into a coherent response.
5. If the information in the knowledge base is insufficient, clearly state the limitations of your answer.
6. When appropriate, structure complex information using bullet points, numbered lists, or other formatting to enhance readability.
7. Maintain a helpful, professional tone in all interactions.
8. If a user asks about calculating BMI, use the action group tool for the calculation.

NEVER:
- Don't make up information that isn't supported by the knowledge base.
- Don't provide partial or incomplete answers when more comprehensive information is available.
- Don't ignore relevant context from previous messages in the conversation.
- Don't respond without consulting the knowledge base unless specifically using a tool.

Your responses should demonstrate deep understanding of the subject matter and provide maximum value to the user.
EOT
agent_description                   = "An advanced RAG-powered AI assistant that provides comprehensive answers from its knowledge base"
agent_actiongroup_descrption        = "Use the action group for specialized calculations and data processing tasks"
kb_instructions_for_agent           = "Search the knowledge base thoroughly for relevant information. Provide comprehensive answers that synthesize all available relevant information. Always cite sources and explain the context. If multiple sources contain relevant information, integrate them into a coherent response. Use direct quotes when appropriate to support your answers."
code_base_zip                       = "package.zip"
code_base_bucket                    = "bedrock-agent-code"
enable_guardrails                   = true
guardrail_name                      = "bedrock-guardrail"
guardrail_blocked_input_messaging   = "This input is not allowed due to content restrictions."
guardrail_blocked_outputs_messaging = "The generated output was blocked due to content restrictions."
guardrail_description               = "A guardrail for Bedrock to ensure safe and appropriate content"
guardrail_content_policy_config = [
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
guardrail_sensitive_information_policy_config = [
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
guardrail_topic_policy_config = [
  {
    topics_config = [
      {
        name       = "investment_advice"
        examples   = ["Where should I invest my money?", "What stocks should I buy?"]
        type       = "DENY"
        definition = "Any advice or recommendations regarding financial investments or asset allocation."
      }
    ]
  }
]
guardrail_word_policy_config = [
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

# Frontend variables (optional)
enable_frontend = false