// Application Insights module

@description('Application Insights name')
param name string

@description('Azure region')
param location string

@description('Email address for alert notifications')
param alertEmailAddress string = ''

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${name}-workspace'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Action group for alert notifications (T103)
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = if (!empty(alertEmailAddress)) {
  name: '${name}-action-group'
  location: 'global'
  properties: {
    groupShortName: 'StitchesAG'
    enabled: true
    emailReceivers: [
      {
        name: 'AdminEmail'
        emailAddress: alertEmailAddress
        useCommonAlertSchema: true
      }
    ]
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
  }
}

// Availability alert
resource availabilityAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${name}-availability-alert'
  location: 'global'
  properties: {
    description: 'Alert when availability drops below 99.5%'
    severity: 1
    enabled: true
    scopes: [appInsights.id]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'AvailabilityCriteria'
          metricName: 'availabilityResults/availabilityPercentage'
          operator: 'LessThan'
          threshold: 99.5
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: !empty(alertEmailAddress) ? [{ actionGroupId: actionGroup.id }] : []
  }
}

// Latency alert (p95 > 500ms)
resource latencyAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${name}-latency-alert'
  location: 'global'
  properties: {
    description: 'Alert when API latency exceeds 500ms at p95'
    severity: 2
    enabled: true
    scopes: [appInsights.id]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'LatencyCriteria'
          metricName: 'requests/duration'
          operator: 'GreaterThan'
          threshold: 500
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: !empty(alertEmailAddress) ? [{ actionGroupId: actionGroup.id }] : []
  }
}

// Error rate alert (> 1%)
resource errorRateAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${name}-error-rate-alert'
  location: 'global'
  properties: {
    description: 'Alert when error rate exceeds 1%'
    severity: 2
    enabled: true
    scopes: [appInsights.id]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'ErrorRateCriteria'
          metricName: 'requests/failed'
          operator: 'GreaterThan'
          threshold: 1
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: !empty(alertEmailAddress) ? [{ actionGroupId: actionGroup.id }] : []
  }
}

output connectionString string = appInsights.properties.ConnectionString
output instrumentationKey string = appInsights.properties.InstrumentationKey
output id string = appInsights.id
