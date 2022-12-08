param kubeletidentityObjectId string = ''

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

resource recordWelkom 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  parent: dnsZone
  name: 'welkom'
  properties: {
    TTL: 3600
    ARecords: [
      {
        ipv4Address: '20.86.245.108'
      }
    ]
  }
}

resource recordShell 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  parent: dnsZone
  name: 'www'
  properties: {
    TTL: 3600
    ARecords: [
      {
        ipv4Address: '20.86.245.108'
      }
    ]
  }
}

resource recordShellRoot 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  parent: dnsZone
  name: '@'
  properties: {
    TTL: 3600
    ARecords: [
      {
        ipv4Address: '20.86.245.108'
      }
    ]
  }
}

resource recordApi1 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  parent: dnsZone
  name: 'api1'
  properties: {
    TTL: 3600
    ARecords: [
      {
        ipv4Address: '20.86.245.108'
      }
    ]
  }
}

resource recordApi2 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  parent: dnsZone
  name: 'api2'
  properties: {
    TTL: 3600
    ARecords: [
      {
        ipv4Address: '20.86.245.108'
      }
    ]
  }
}
