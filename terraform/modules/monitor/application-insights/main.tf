resource "azurerm_application_insights" "application_insights" {
  name                = "${var.app_name}-application-insights" 
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = var.workspace_id

  tags = {
    Owner = var.owner_tag
  }
}

resource "azurerm_portal_dashboard" "dashboard" {
  name                 = "${var.app_name}-dashboard"
  resource_group_name  = var.resource_group_name
  location             = var.location

  tags = {
    Owner = var.owner_tag
  }

  dashboard_properties = <<DASH
{
  "lenses": {
    "0": {
      "order": 0,
      "parts": {
        "0": {
          "position": {
            "x": 0,
            "y": 0,
            "colSpan": 2,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "### App performance",
                  "title": "",
                  "subtitle": "",
                  "markdownSource": 1,
                  "markdownUri": null
                }
              }
            }
          }
        },
        "1": {
          "position": {
            "x": 2,
            "y": 0,
            "colSpan": 6,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "AverageMemoryWorkingSet",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Average memory working set"
                        }
                      }
                    ],
                    "title": "Average memory usage over time",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      }
                    },
                    "timespan": {
                      "relative": {
                        "duration": 86400000
                      },
                      "showUTCTime": false,
                      "grain": 1
                    }
                  }
                },
                "isOptional": true
              },
              {
                "name": "sharedTimeRange",
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "AverageMemoryWorkingSet",
                        "aggregationType": 4,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Average memory working set"
                        }
                      }
                    ],
                    "title": "Average memory usage over time",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false,
                        "hideHoverCard": false,
                        "hideLabelNames": true
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    }
                  }
                }
              }
            }
          }
        },
        "2": {
          "position": {
            "x": 8,
            "y": 0,
            "colSpan": 6,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "CpuTime",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "CPU Time"
                        }
                      }
                    ],
                    "title": "Average memory usage over time",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      }
                    },
                    "timespan": {
                      "relative": {
                        "duration": 86400000
                      },
                      "showUTCTime": false,
                      "grain": 1
                    }
                  }
                },
                "isOptional": true
              },
              {
                "name": "sharedTimeRange",
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "CpuTime",
                        "aggregationType": 1,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "CPU Time"
                        }
                      }
                    ],
                    "title": "CPU consumption",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false,
                        "hideHoverCard": false,
                        "hideLabelNames": true
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    }
                  }
                }
              }
            }
          }
        },
        "3": {
          "position": {
            "x": 0,
            "y": 3,
            "colSpan": 2,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "### Usage",
                  "title": "",
                  "subtitle": "",
                  "markdownSource": 1,
                  "markdownUri": null
                }
              }
            }
          }
        },
        "4": {
          "position": {
            "x": 2,
            "y": 3,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "ResourceId",
                "value": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Insights/components/${azurerm_application_insights.application_insights.name}"
              },
              {
                "name": "ComponentId",
                "value": {
                  "SubscriptionId": "${var.subscription_id}",
                  "ResourceGroup": "${var.resource_group_name}",
                  "Name": "${azurerm_application_insights.application_insights.name}",
                  "LinkedApplicationType": 0,
                  "ResourceId": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Insights/components/${azurerm_application_insights.application_insights.name}",
                  "ResourceType": "microsoft.insights/components",
                  "IsAzureFirst": false
                }
              },
              {
                "name": "TargetBlade",
                "value": "Performance"
              },
              {
                "name": "DataModel",
                "value": {
                  "version": "1.0.0",
                  "experience": 1,
                  "clientTypeMode": "Server",
                  "timeContext": {
                    "durationMs": 86400000,
                    "createdTime": "2025-06-07T09:34:06.365Z",
                    "isInitialTime": false,
                    "grain": 1,
                    "useDashboardTimeRange": false
                  },
                  "prefix": "let OperationIdsWithExceptionType = (excType: string) { exceptions | where timestamp > ago(1d) \n    | where tobool(iff(excType == \"null\", isempty(type), type == excType)) \n    | distinct operation_ParentId };\nlet OperationIdsWithFailedReqResponseCode = (respCode: string) { requests | where timestamp > ago(1d)\n    | where iff(respCode == \"null\", isempty(resultCode), resultCode == respCode) and success == false \n    | distinct id };\nlet OperationIdsWithFailedDependencyType = (depType: string) { dependencies | where timestamp > ago(1d)\n    | where iff(depType == \"null\", isempty(type), type == depType) and success == false \n    | distinct operation_ParentId };\nlet OperationIdsWithFailedDepResponseCode = (respCode: string) { dependencies | where timestamp > ago(1d)\n    | where iff(respCode == \"null\", isempty(resultCode), resultCode == respCode) and success == false \n    | distinct operation_ParentId };\nlet OperationIdsWithExceptionBrowser = (browser: string) { exceptions | where timestamp > ago(1d)\n    | where tobool(iff(browser == \"null\", isempty(client_Browser), client_Browser == browser)) \n    | distinct operation_ParentId };",
                  "percentile": 1,
                  "grain": "5m",
                  "selectedOperation": null,
                  "selectedOperationName": null,
                  "filters": [
                    {
                      "kql": "1 == 1",
                      "table": "",
                      "name": "",
                      "operator": "==",
                      "values": [],
                      "builtIn": false,
                      "canEdit": true
                    }
                  ]
                },
                "isOptional": true
              },
              {
                "name": "Version",
                "value": "1.0"
              }
            ],
            "type": "Extension/AppInsightsExtension/PartType/PerformanceCuratedPinnedChartPart",
            "asset": {
              "idInputName": "ResourceId",
              "type": "ApplicationInsights"
            },
            "partHeader": {
              "title": "Response time",
              "subtitle": ""
            }
          }
        },
        "5": {
          "position": {
            "x": 8,
            "y": 3,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "Requests",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Requests"
                        }
                      }
                    ],
                    "title": "Total requests",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      }
                    },
                    "timespan": {
                      "relative": {
                        "duration": 2592000000
                      },
                      "showUTCTime": false,
                      "grain": 1
                    }
                  }
                },
                "isOptional": true
              },
              {
                "name": "sharedTimeRange",
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "Requests",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Requests"
                        }
                      }
                    ],
                    "title": "Total requests",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    }
                  }
                }
              }
            },
            "filters": {
              "MsPortalFx_TimeRange": {
                "model": {
                  "format": "local",
                  "granularity": "auto",
                  "relative": "43200m"
                }
              }
            }
          }
        },
        "6": {
          "position": {
            "x": 0,
            "y": 7,
            "colSpan": 2,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "### Http codes",
                  "title": "",
                  "subtitle": "",
                  "markdownSource": 1,
                  "markdownUri": null
                }
              }
            }
          }
        },
        "7": {
          "position": {
            "x": 2,
            "y": 7,
            "colSpan": 6,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "Http5xx",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Http Server Errors"
                        }
                      }
                    ],
                    "title": "Count of Http server errors",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      }
                    },
                    "timespan": {
                      "relative": {
                        "duration": 2592000000
                      },
                      "showUTCTime": false,
                      "grain": 1
                    }
                  }
                },
                "isOptional": true
              },
              {
                "name": "sharedTimeRange",
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "Http5xx",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Http Server Errors"
                        }
                      }
                    ],
                    "title": "Http server errors",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false,
                        "hideHoverCard": false,
                        "hideLabelNames": true
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    }
                  }
                }
              }
            }
          }
        },
        "8": {
          "position": {
            "x": 8,
            "y": 7,
            "colSpan": 6,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "Http401",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Http 401"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "Http403",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Http 403"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "Http404",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Http 404"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "Http404",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Http 404"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "Http406",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Http 406"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "Http2xx",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Http 2xx"
                        }
                      }
                    ],
                    "title": "Count of Http status codes",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      }
                    },
                    "timespan": {
                      "relative": {
                        "duration": 2592000000
                      },
                      "showUTCTime": false,
                      "grain": 1
                    }
                  }
                },
                "isOptional": true
              },
              {
                "name": "sharedTimeRange",
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "Http401",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Http 401"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "Http403",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Http 403"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "Http404",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Http 404"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "Http404",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Http 404"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "Http406",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Http 406"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "Http2xx",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Http 2xx"
                        }
                      }
                    ],
                    "title": "Http status codes",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false,
                        "hideHoverCard": false,
                        "hideLabelNames": true
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    }
                  }
                }
              }
            }
          }
        },
        "9": {
          "position": {
            "x": 0,
            "y": 10,
            "colSpan": 2,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "### Bandwidth",
                  "title": "",
                  "subtitle": "",
                  "markdownSource": 1,
                  "markdownUri": null
                }
              }
            }
          }
        },
        "10": {
          "position": {
            "x": 2,
            "y": 10,
            "colSpan": 6,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "BytesSent",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Data Out"
                        }
                      }
                    ],
                    "title": "Outgoing bandwidth",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      }
                    },
                    "timespan": {
                      "relative": {
                        "duration": 2592000000
                      },
                      "showUTCTime": false,
                      "grain": 1
                    }
                  }
                },
                "isOptional": true
              },
              {
                "name": "sharedTimeRange",
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "BytesSent",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Data Out"
                        }
                      }
                    ],
                    "title": "Outgoing bandwidth",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    }
                  }
                }
              }
            }
          }
        },
        "11": {
          "position": {
            "x": 8,
            "y": 10,
            "colSpan": 6,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "BytesReceived",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Data In"
                        }
                      }
                    ],
                    "title": "Incoming bandwidth",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      }
                    },
                    "timespan": {
                      "relative": {
                        "duration": 2592000000
                      },
                      "showUTCTime": false,
                      "grain": 1
                    }
                  }
                },
                "isOptional": true
              },
              {
                "name": "sharedTimeRange",
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites/${var.app_name}"
                        },
                        "name": "BytesReceived",
                        "aggregationType": 7,
                        "namespace": "microsoft.web/sites",
                        "metricVisualization": {
                          "displayName": "Data In"
                        }
                      }
                    ],
                    "title": "Incoming bandwidth",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    }
                  }
                }
              }
            }
          }
        },
        "12": {
          "position": {
            "x": 0,
            "y": 17,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "sharedTimeRange",
                "isOptional": true
              },
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Insights/components/${azurerm_application_insights.application_insights.name}"
                        },
                        "name": "requests/failed",
                        "aggregationType": 1,
                        "namespace": "microsoft.insights/components/kusto",
                        "metricVisualization": {
                          "displayName": "Failed requests"
                        }
                      }
                    ],
                    "title": "Failed requests",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideHoverCard": false,
                        "hideLabelNames": true
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      }
                    },
                    "timespan": {
                      "relative": {
                        "duration": 86400000
                      },
                      "showUTCTime": false,
                      "grain": 1
                    }
                  }
                },
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Insights/components/${azurerm_application_insights.application_insights.name}"
                        },
                        "name": "requests/failed",
                        "aggregationType": 1,
                        "namespace": "microsoft.insights/components/kusto",
                        "metricVisualization": {
                          "displayName": "Failed requests"
                        }
                      }
                    ],
                    "title": "Failed requests",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideHoverCard": false,
                        "hideLabelNames": true
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    }
                  }
                }
              }
            },
            "filters": {
              "MsPortalFx_TimeRange": {
                "model": {
                  "format": "local",
                  "granularity": "auto",
                  "relative": "1440m"
                }
              }
            }
          }
        }
      }
    }
  }
}
DASH
}
