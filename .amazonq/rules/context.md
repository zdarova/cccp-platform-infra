# CCCP Platform Infrastructure - Project Rules

## Project Context
This is the **infrastructure-as-code** repository for the Call Centre Cognitive Platform (CCCP). It provisions all Azure resources using Bicep.

## Current Deployment State
- **Resource Group**: `rg-cccp-poc` (westeurope)
- **Azure OpenAI**: `oai-cccp-pibz5vm5tus3o` (westeurope) — GPT-5.4 GlobalStandard + text-embedding-3-small + Whisper
- **PostgreSQL Flexible**: `pg-cccp-pibz5vm5tus3o` (westeurope) — B1ms, pgvector enabled, database `cccp`
- **Container Apps Environment**: `cae-cccp-pibz5vm5tus3o` (northeurope) — separate region due to westeurope capacity issues
- **Chatbot**: `cccp-chatbot.agreeablecliff-8b7135c2.northeurope.azurecontainerapps.io`
- **Real-time Agent**: `cccp-realtime.agreeablecliff-8b7135c2.northeurope.azurecontainerapps.io`
- **Event Hubs**: `eh-cccp-pibz5vm5tus3o` (westeurope)
- **Cosmos DB**: `cosmos-cccp-pibz5vm5tus3o` (westeurope, serverless)
- **Storage**: `stcccppibz5vm5tus3o` (westeurope) — containers: recordings, transcripts
- **ACR**: `crcccppibz5vm5tus3o` (westeurope)
- **Key Vault**: `kv-cccp-pibz5vm5tus3o` (westeurope)
- **Log Analytics**: `log-cccp-pibz5vm5tus3o` (westeurope)
- **Speech**: `speech-cccp-pibz5vm5tus3o` (westeurope)

## Architecture Decisions
- **PostgreSQL Flexible Server (B1ms)** with pgvector for BOTH vector search (RAG) AND structured data (replaces Snowflake for PoC). In production, structured data moves to Snowflake.
- **GPT-5.4 (GlobalStandard)** — latest available model, shared global quota pool.
- **Container Apps in northeurope** — westeurope had ManagedEnvironmentCapacityHeavyUsageError. Cross-region latency is negligible for a PoC.
- **Databricks replaced by mock API** — predictive microservices simulated in code. Architecture diagram still shows Databricks as production target.
- **No Snowflake** — all structured data (customers, KPIs, call metadata, themes) in PostgreSQL tables. Same SQL interface, easy to swap back.

## Design Principles
- SaaS-first, usage-based pricing, minimal operational overhead
- Scale-to-zero where possible (Container Apps, Cosmos serverless)
- All secrets in GitHub Secrets, passed via Container App env vars
- OIDC federated credentials for GitHub Actions → Azure (service principal: sp-cccp-github)

## CI/CD
- GitHub Actions with OIDC (no stored credentials)
- Service Principal: `sp-cccp-github` (client-id: 81747ea9-90c0-47fe-be30-e6feb2368ab0)
- Federated credentials configured for all 4 repos (main branch)
- `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true` on all workflows

## Cost (Idle)
- ~€13/2 weeks (PostgreSQL B1ms + Event Hubs Basic)
