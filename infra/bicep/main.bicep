// =============================================================================
// CEPAC — Azure Infrastructure (Bicep)
// Resource group: rg_spurbanismo_cepac | Region: East US
// Subscription: 506f92c4-471f-4f5f-8b5c-9ff96ad5ce8c
//
// Recursos criados:
//   - Azure Container Registry (cepacregistry)
//   - Azure Database for PostgreSQL Flexible Server 15 (cepac-pg)
//   - Azure Storage Account (cepacstorageacct) + Blob Container (cepac-documentos)
//   - Log Analytics Workspace (cepac-logs)
//   - Container Apps Environment (cepac-env)
//   - Container Apps: cepac-api, cepac-portal, cepac-dashboard
//
// Deploy:
//   az deployment group create \
//     --resource-group rg_spurbanismo_cepac \
//     --template-file infra/bicep/main.bicep \
//     --parameters @infra/bicep/main.parameters.json
// =============================================================================

targetScope = 'resourceGroup'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@description('Azure AD Tenant ID para autenticação JWT')
param azureAdTenantId string

@description('Client ID do App Registration CEPAC (API)')
param azureAdClientId string

@description('Login do administrador do PostgreSQL (sem caracteres especiais)')
param dbAdminLogin string

@description('Senha do administrador do PostgreSQL')
@secure()
param dbAdminPassword string

@description('Tag de imagem do container (ex: sha-abc123). Use "placeholder" no deploy inicial — CI substitui pela imagem real.')
param imageTag string = 'placeholder'

@description('Region para todos os recursos')
param location string = resourceGroup().location

@description('Region para o PostgreSQL Flexible Server (pode diferir da região principal se houver restrição de cota)')
param pgLocation string = 'eastus2'

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

var acrName = 'cepacregistry'
// Login server é previsível: {nome}.azurecr.io — evita referência dinâmica que falha na validação do ARM
var acrLoginServer = '${acrName}.azurecr.io'
var pgServerName = 'cepac-pg'
var storageAccountName = 'cepacstorageacct'
var blobContainerName = 'cepac-documentos'
var logAnalyticsName = 'cepac-logs'
var containerEnvName = 'cepac-env'

// Imagem placeholder (Container Apps Hello World) usada no deploy inicial enquanto
// o ACR está vazio. O pipeline CI substitui com a imagem real via imageTag.
var usePlaceholder = imageTag == 'placeholder'
var placeholderImage = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

// ---------------------------------------------------------------------------
// Azure Container Registry
// ---------------------------------------------------------------------------

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

// ---------------------------------------------------------------------------
// Azure Database for PostgreSQL Flexible Server 15
// ---------------------------------------------------------------------------

resource pgServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: pgServerName
  location: pgLocation
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: dbAdminLogin
    administratorLoginPassword: dbAdminPassword
    version: '15'
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Disabled'
      passwordAuth: 'Enabled'
    }
  }
}

resource pgDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-06-01-preview' = {
  parent: pgServer
  name: 'cepac'
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

// Permite tráfego de serviços Azure (inclui Container Apps)
resource pgFirewallAzureServices 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-06-01-preview' = {
  parent: pgServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// ---------------------------------------------------------------------------
// Azure Storage Account + Blob Container (T13 — documentos processo)
// ---------------------------------------------------------------------------

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-04-01' = {
  parent: storageAccount
  name: 'default'
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: blobService
  name: blobContainerName
  properties: {
    publicAccess: 'None'
  }
}

// ---------------------------------------------------------------------------
// Log Analytics Workspace (necessário para Container Apps Environment)
// ---------------------------------------------------------------------------

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// ---------------------------------------------------------------------------
// Container Apps Environment
// ---------------------------------------------------------------------------

resource containerEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerEnvName
  location: location
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

// ---------------------------------------------------------------------------
// Container App — API (FastAPI)
// ---------------------------------------------------------------------------

resource apiApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'cepac-api'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8000
        transport: 'http'
        allowInsecure: false
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
      registries: usePlaceholder ? [] : [
        {
          server: acrLoginServer
          identity: 'system'
        }
      ]
      secrets: [
        {
          name: 'database-url'
          // asyncpg requer ?ssl=require para Azure PostgreSQL Flexible Server
          value: 'postgresql+asyncpg://${dbAdminLogin}:${dbAdminPassword}@${pgServer.properties.fullyQualifiedDomainName}:5432/cepac?ssl=require'
        }
        {
          name: 'blob-account-key'
          value: storageAccount.listKeys().keys[0].value
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'cepac-api'
          image: usePlaceholder ? placeholderImage : '${acrLoginServer}/cepac-api:${imageTag}'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'DATABASE_URL'
              secretRef: 'database-url'
            }
            {
              name: 'AZURE_AD_TENANT_ID'
              value: azureAdTenantId
            }
            {
              name: 'AZURE_AD_CLIENT_ID'
              value: azureAdClientId
            }
            {
              name: 'AZURE_BLOB_ACCOUNT_NAME'
              value: storageAccountName
            }
            {
              name: 'AZURE_BLOB_ACCOUNT_KEY'
              secretRef: 'blob-account-key'
            }
            {
              name: 'AZURE_BLOB_CONTAINER_NAME'
              value: blobContainerName
            }
            {
              // Após primeiro deploy: substitua por URLs reais dos Container Apps
              // Ex: https://cepac-portal.xyz.eastus.azurecontainerapps.io,https://cepac-dashboard.xyz.eastus.azurecontainerapps.io
              name: 'CORS_ORIGINS'
              value: '*'
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 8000
              }
              initialDelaySeconds: 10
              periodSeconds: 30
              failureThreshold: 3
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/health'
                port: 8000
              }
              initialDelaySeconds: 5
              periodSeconds: 10
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Container App — Portal (React SPA)
// ---------------------------------------------------------------------------

resource portalApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'cepac-portal'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 3000
        transport: 'http'
        allowInsecure: false
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
      registries: usePlaceholder ? [] : [
        {
          server: acrLoginServer
          identity: 'system'
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'cepac-portal'
          image: usePlaceholder ? placeholderImage : '${acrLoginServer}/cepac-portal:${imageTag}'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 3000
              }
              initialDelaySeconds: 5
              periodSeconds: 30
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Container App — Dashboard (React SPA)
// ---------------------------------------------------------------------------

resource dashboardApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'cepac-dashboard'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 3001
        transport: 'http'
        allowInsecure: false
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
      registries: usePlaceholder ? [] : [
        {
          server: acrLoginServer
          identity: 'system'
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'cepac-dashboard'
          image: usePlaceholder ? placeholderImage : '${acrLoginServer}/cepac-dashboard:${imageTag}'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 3001
              }
              initialDelaySeconds: 5
              periodSeconds: 30
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 2
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '30'
              }
            }
          }
        ]
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Role assignment: ACR Pull para cada Container App (managed identity)
// ---------------------------------------------------------------------------

var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource apiAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, apiApp.id, acrPullRoleId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: apiApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource portalAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, portalApp.id, acrPullRoleId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: portalApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource dashboardAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, dashboardApp.id, acrPullRoleId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: dashboardApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output acrLoginServer string = acrLoginServer
output pgServerFqdn string = pgServer.properties.fullyQualifiedDomainName
output containerEnvId string = containerEnv.id
output apiAppUrl string = 'https://${apiApp.properties.configuration.ingress.fqdn}'
output portalAppUrl string = 'https://${portalApp.properties.configuration.ingress.fqdn}'
output dashboardAppUrl string = 'https://${dashboardApp.properties.configuration.ingress.fqdn}'
output storageAccountName string = storageAccount.name
