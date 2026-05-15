# CCCP - Platform Infrastructure (IaC)

Azure infrastructure for the Call Centre Cognitive Platform, managed with Bicep.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│              CALL CENTRE COGNITIVE PLATFORM (CCCP)                │
├───────────────┬──────────────────┬──────────────────────────────┤
│  REAL-TIME    │  POST-CALL       │  INTERACTIVE CHATBOT          │
│  Genesys →   │  Recordings →    │  Teams Bot →                  │
│  Event Hub →  │  Blob → Batch →  │  Multi-Agent RAG →            │
│  Stream →     │  Knowledge Repo  │  Insights                     │
│  Agent Copilot│                  │                               │
├───────────────┴──────────────────┴──────────────────────────────┤
│  SHARED: Azure OpenAI | AI Search | Cosmos DB | Event Hubs       │
│  EXISTING: Snowflake | Databricks | SharePoint                   │
└─────────────────────────────────────────────────────────────────┘
```

## Resources Provisioned

| Resource | Service | Purpose |
|----------|---------|---------|
| Azure OpenAI | GPT-4o + Whisper | LLM + transcription |
| Azure AI Speech | Real-time STT | Live call transcription |
| Azure AI Search | Vector + semantic | RAG over transcripts & guidance |
| Azure Event Hubs | Streaming | Real-time call events |
| Azure Stream Analytics | CEP | Sentiment windowing |
| Azure Container Apps | Serverless | Chatbot + real-time APIs |
| Azure Bot Service | Teams integration | Chatbot channel |
| Cosmos DB | Serverless | Conversation state + metadata |
| Blob Storage | LRS | Recordings + transcripts |
| Azure Data Factory | Orchestration | Post-call batch pipelines |
| Key Vault | Secrets | API keys + connection strings |
| Log Analytics | Monitoring | LLMOps observability |

## Deploy

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

## Cost Estimate (Idle / No Traffic)

~€40/2 weeks — mainly Azure AI Search Basic tier. Everything else scales to zero.

## Related Repos

- **cccp-realtime-agent** — Real-time call processing (streaming + agent copilot)
- **cccp-post-call-analytics** — Batch pipeline for recordings analysis
- **cccp-chatbot** — Multi-agent Teams chatbot
