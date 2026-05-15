# CCCP Platform Infrastructure - Project Rules

## Project Context
This is the **infrastructure-as-code** repository for the Call Centre Cognitive Platform (CCCP). It provisions all Azure resources using Bicep.

## Architecture Decisions
- **PostgreSQL Flexible Server (B1ms)** with pgvector extension for vector search (RAG). Chosen over Azure AI Search for cost efficiency in PoC (~€6/2wk vs €33/2wk). At <1000 vectors, performance is equivalent.
- **Azure OpenAI (GPT-4o)** for LLM tasks: summarization, sentiment, recommendations, response generation.
- **Azure AI Speech** for real-time speech-to-text during live calls.
- **Azure Event Hubs (Basic)** for streaming call transcription events.
- **Azure Container Apps (consumption)** for serverless API hosting (scale to zero).
- **Azure Bot Service** for Microsoft Teams chatbot integration.
- **Cosmos DB (serverless)** for conversation state and call metadata.
- **Azure Blob Storage** for call recordings and transcripts.
- **Azure Data Factory** for orchestrating post-call batch pipelines.
- **Existing client systems**: Snowflake (DWH), Databricks (ML), SharePoint (guidance docs), Genesys (call centre).

## Design Principles
- SaaS-first, usage-based pricing, minimal operational overhead
- Scale-to-zero where possible (Container Apps, Cosmos serverless, Event Hubs Basic)
- Integration with existing client ecosystem (Snowflake, Databricks, SharePoint, Genesys)
- Separation of concerns: infra repo deploys resources, application repos deploy code
- All secrets in Key Vault, referenced by Container Apps and Data Factory

## Naming Convention
- Resource Group: `rg-cccp-poc`
- Resources: `{type}-cccp-{suffix}` (e.g., `pg-cccp-poc`, `oai-cccp-poc`, `ca-cccp-poc`)

## Cost Target
- PoC idle (no traffic): <€15/2 weeks
- PoC active (demo): <€50/2 weeks
