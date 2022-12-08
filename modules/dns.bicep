param kubeletidentityObjectId string = ''

param prefixes array = []

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: 'maffe-maandag.nl'
}

var dnsZoneContributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'befefa01-2a29-4197-83a8-272ff33ce314')
resource dnsZoneContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, dnsZone.id, dnsZoneContributorRoleDefinitionId)
  scope: dnsZone
  properties: {
    principalId: kubeletidentityObjectId
    roleDefinitionId: dnsZoneContributorRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}

resource record 'Microsoft.Network/dnsZones/A@2018-05-01' = [for prefix in prefixes: {
  parent: dnsZone
  name: prefix
  properties: {
    TTL: 3600
    ARecords: [
      {
        ipv4Address: '20.86.245.108'
      }
    ]
  }
}]
