// CCCP - Call Centre Cognitive Platform - Infrastructure
// All Azure resources for the PoC

@description('Location for all resources')
param location string = 'westeurope'

@description('Location for Container Apps (separate to avoid capacity issues)')
param containerAppsLocation string = 'northeurope'

@description('Unique suffix for resource names')
param suffix string = uniqueString(resourceGroup().id)

@description('PostgreSQL admin password')
@secure()
param pgPassword string

// --- Azure OpenAI ---
resource openai 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: 'oai-cccp-${suffix}'
  location: 'westeurope'
  kind: 'OpenAI'
  sku: { name: 'S0' }
  properties: {
    publicNetworkAccess: 'Enabled'
    customSubDomainName: 'oai-cccp-${suffix}'
  }
}

resource gpt4o 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: openai
  name: 'gpt-5-4'
  sku: { name: 'GlobalStandard', capacity: 30 }
  properties: {
    model: { format: 'OpenAI', name: 'gpt-5.4', version: '2026-03-05' }
  }
}

resource embedding 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: openai
  name: 'text-embedding-3-small'
  sku: { name: 'GlobalStandard', capacity: 120 }
  properties: {
    model: { format: 'OpenAI', name: 'text-embedding-3-small', version: '1' }
  }
  dependsOn: [gpt4o]
}

resource whisper 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: openai
  name: 'whisper'
  sku: { name: 'Standard', capacity: 3 }
  properties: {
    model: { format: 'OpenAI', name: 'whisper', version: '001' }
  }
  dependsOn: [embedding]
}

// --- Azure AI Speech ---
resource speech 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: 'speech-cccp-${suffix}'
  location: location
  kind: 'SpeechServices'
  sku: { name: 'S0' }
  properties: { publicNetworkAccess: 'Enabled' }
}

// --- PostgreSQL Flexible Server (pgvector) ---
resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2023-12-01-preview' = {
  name: 'pg-cccp-${suffix}'
  location: location
  sku: { name: 'Standard_B1ms', tier: 'Burstable' }
  properties: {
    version: '16'
    administratorLogin: 'pgadmin'
    administratorLoginPassword: pgPassword
    storage: { storageSizeGB: 32 }
    highAvailability: { mode: 'Disabled' }
  }
}

resource pgFirewall 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-12-01-preview' = {
  parent: postgres
  name: 'AllowAzure'
  properties: { startIpAddress: '0.0.0.0', endIpAddress: '0.0.0.0' }
}

resource pgExtensions 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2023-12-01-preview' = {
  parent: postgres
  name: 'azure.extensions'
  properties: { value: 'vector', source: 'user-override' }
}

// --- Event Hubs (streaming) ---
resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' = {
  name: 'eh-cccp-${suffix}'
  location: location
  sku: { name: 'Basic', tier: 'Basic', capacity: 1 }
}

resource eventHubCalls 'Microsoft.EventHub/namespaces/eventhubs@2024-01-01' = {
  parent: eventHubNamespace
  name: 'call-transcripts'
  properties: { messageRetentionInDays: 1, partitionCount: 2 }
}

// --- Cosmos DB (serverless) ---
resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: 'cosmos-cccp-${suffix}'
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    capabilities: [{ name: 'EnableServerless' }]
    locations: [{ locationName: location, failoverPriority: 0 }]
  }
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmos
  name: 'cccp'
  properties: { resource: { id: 'cccp' } }
}

resource cosmosDocuments 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  parent: cosmosDb
  name: 'documents'
  properties: {
    resource: {
      id: 'documents'
      partitionKey: { paths: ['/filename'], kind: 'Hash' }
    }
  }
}

resource cosmosConversations 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  parent: cosmosDb
  name: 'conversations'
  properties: {
    resource: {
      id: 'conversations'
      partitionKey: { paths: ['/session_id'], kind: 'Hash' }
    }
  }
}

// --- Storage Account (recordings + transcripts) ---
resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'stcccp${suffix}'
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: { accessTier: 'Hot' }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storage
  name: 'default'
}

resource recordingsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'recordings'
}

resource transcriptsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'transcripts'
}

resource documentsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'documents'
}

// --- Container Registry ---
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'crcccp${suffix}'
  location: location
  sku: { name: 'Basic' }
  properties: { adminUserEnabled: true }
}

// --- Log Analytics ---
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-cccp-${suffix}'
  location: location
  properties: { sku: { name: 'PerGB2018' }, retentionInDays: 30 }
}

// --- Container Apps Environment ---
resource containerEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'cae-cccp-${suffix}'
  location: containerAppsLocation
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// --- Container App: Chatbot ---
resource chatbotApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'cccp-chatbot'
  location: containerAppsLocation
  properties: {
    managedEnvironmentId: containerEnv.id
    configuration: {
      ingress: { external: true, targetPort: 8000, transport: 'http' }
      registries: [{ server: '${acr.name}.azurecr.io', username: acr.listCredentials().username, passwordSecretRef: 'acr-password' }]
      secrets: [{ name: 'acr-password', value: acr.listCredentials().passwords[0].value }]
    }
    template: {
      containers: [{
        name: 'chatbot'
        image: '${acr.name}.azurecr.io/cccp-chatbot:latest'
        resources: { cpu: json('0.5'), memory: '1Gi' }
        env: [
          { name: 'AZURE_OPENAI_ENDPOINT', value: openai.properties.endpoint }
          { name: 'AZURE_OPENAI_KEY', value: openai.listKeys().key1 }
          { name: 'AZURE_OPENAI_CHAT_DEPLOYMENT', value: 'gpt-5-4' }
          { name: 'AZURE_OPENAI_EMBEDDING_DEPLOYMENT', value: 'text-embedding-3-small' }
          { name: 'PG_CONNECTION_STRING', value: 'host=${postgres.properties.fullyQualifiedDomainName} port=5432 dbname=cccp user=pgadmin password=${pgPassword} sslmode=require' }
          { name: 'COSMOS_ENDPOINT', value: cosmos.properties.documentEndpoint }
          { name: 'COSMOS_KEY', value: cosmos.listKeys().primaryMasterKey }
          { name: 'AZURE_STORAGE_CONNECTION', value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net' }
        ]
      }]
      scale: { minReplicas: 0, maxReplicas: 3 }
    }
  }
}

// --- Container App: Real-time Agent ---
resource realtimeApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'cccp-realtime'
  location: containerAppsLocation
  properties: {
    managedEnvironmentId: containerEnv.id
    configuration: {
      ingress: { external: true, targetPort: 8001, transport: 'http' }
      registries: [{ server: '${acr.name}.azurecr.io', username: acr.listCredentials().username, passwordSecretRef: 'acr-password' }]
      secrets: [{ name: 'acr-password', value: acr.listCredentials().passwords[0].value }]
    }
    template: {
      containers: [{
        name: 'realtime'
        image: '${acr.name}.azurecr.io/cccp-realtime:latest'
        resources: { cpu: json('0.5'), memory: '1Gi' }
        env: [
          { name: 'AZURE_OPENAI_ENDPOINT', value: openai.properties.endpoint }
          { name: 'AZURE_OPENAI_KEY', value: openai.listKeys().key1 }
          { name: 'AZURE_SPEECH_KEY', value: speech.listKeys().key1 }
          { name: 'AZURE_SPEECH_REGION', value: location }
          { name: 'EVENT_HUB_CONNECTION', value: eventHubNamespace.listKeys().primaryConnectionString }
          { name: 'PG_CONNECTION_STRING', value: 'host=${postgres.properties.fullyQualifiedDomainName} port=5432 dbname=cccp user=pgadmin password=${pgPassword} sslmode=require' }
        ]
      }]
      scale: { minReplicas: 0, maxReplicas: 3 }
    }
  }
}

// --- Key Vault ---
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-cccp-${suffix}'
  location: location
  properties: {
    sku: { family: 'A', name: 'standard' }
    tenantId: subscription().tenantId
    accessPolicies: []
    enableSoftDelete: false
  }
}

// --- Outputs ---
output openaiEndpoint string = openai.properties.endpoint
output postgresHost string = postgres.properties.fullyQualifiedDomainName
output cosmosEndpoint string = cosmos.properties.documentEndpoint
output eventHubNamespace string = eventHubNamespace.name
output chatbotUrl string = chatbotApp.properties.configuration.ingress.fqdn
output realtimeUrl string = realtimeApp.properties.configuration.ingress.fqdn
output acrName string = acr.name
output storageAccount string = storage.name
