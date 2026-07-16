$base = "http://fastory-dev-alb-388858777.us-east-1.elb.amazonaws.com/grafana"
$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:admin123"))
    "Content-Type" = "application/json"
}

$infraDashboard = @'
{
  "dashboard": {
    "title": "Fastory - Live Cluster Infrastructure",
    "tags": ["fastory", "infrastructure", "devops"],
    "timezone": "browser",
    "refresh": "10s",
    "time": {"from": "now-1h", "to": "now"},
    "panels": [
      {
        "id": 100,
        "title": "",
        "type": "text",
        "gridPos": {"h": 2, "w": 24, "x": 0, "y": 0},
        "options": {
          "mode": "markdown",
          "content": "# 🏗️ Fastory Platform — Real-Time Infrastructure Monitoring\n**Cluster:** fastory-dev | **Region:** us-east-1 | **Stack:** ECS Fargate + RDS + Prometheus + Loki + Grafana"
        }
      },
      {
        "id": 1,
        "title": "🟢 Services UP",
        "type": "stat",
        "gridPos": {"h": 5, "w": 4, "x": 0, "y": 2},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [{"expr": "count(up == 1)", "legendFormat": "UP"}],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "fixed", "fixedColor": "green"},
            "thresholds": {"steps": [{"color": "green", "value": null}]}
          }
        }
      },
      {
        "id": 2,
        "title": "🔴 Services DOWN",
        "type": "stat",
        "gridPos": {"h": 5, "w": 4, "x": 4, "y": 2},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [{"expr": "count(up == 0) OR vector(0)", "legendFormat": "DOWN"}],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {"steps": [{"color": "green", "value": null}, {"color": "red", "value": 1}]}
          }
        }
      },
      {
        "id": 3,
        "title": "⏱️ Prometheus Uptime",
        "type": "stat",
        "gridPos": {"h": 5, "w": 4, "x": 8, "y": 2},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [{"expr": "time() - process_start_time_seconds{job=\"prometheus\"}", "legendFormat": "uptime"}],
        "fieldConfig": {
          "defaults": {
            "unit": "dtdurations",
            "color": {"mode": "fixed", "fixedColor": "blue"},
            "thresholds": {"steps": [{"color": "blue", "value": null}]}
          }
        }
      },
      {
        "id": 4,
        "title": "🧠 Goroutines Activas",
        "type": "stat",
        "gridPos": {"h": 5, "w": 4, "x": 12, "y": 2},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [{"expr": "sum(go_goroutines)", "legendFormat": "goroutines"}],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "fixed", "fixedColor": "purple"},
            "thresholds": {"steps": [{"color": "purple", "value": null}]}
          }
        }
      },
      {
        "id": 5,
        "title": "📊 Series Activas",
        "type": "stat",
        "gridPos": {"h": 5, "w": 4, "x": 16, "y": 2},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [{"expr": "prometheus_tsdb_head_series", "legendFormat": "series"}],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "fixed", "fixedColor": "orange"},
            "thresholds": {"steps": [{"color": "orange", "value": null}]}
          }
        }
      },
      {
        "id": 6,
        "title": "📦 File Descriptors",
        "type": "gauge",
        "gridPos": {"h": 5, "w": 4, "x": 20, "y": 2},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [{"expr": "process_open_fds{job=\"prometheus\"} / process_max_fds{job=\"prometheus\"} * 100", "legendFormat": "FD Usage %"}],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0, "max": 100,
            "thresholds": {"steps": [{"color": "green", "value": null}, {"color": "yellow", "value": 50}, {"color": "red", "value": 80}]}
          }
        }
      },
      {
        "id": 7,
        "title": "CPU Usage — Process (rate 5m)",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 7},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [
          {"expr": "rate(process_cpu_seconds_total{job=\"prometheus\"}[5m]) * 100", "legendFormat": "Prometheus"},
          {"expr": "rate(process_cpu_seconds_total{job=\"fastory-backend\"}[5m]) * 100", "legendFormat": "Backend"}
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "color": {"mode": "palette-classic"},
            "custom": {"fillOpacity": 20, "lineWidth": 2, "spanNulls": true, "showPoints": "auto", "pointSize": 5}
          }
        }
      },
      {
        "id": 8,
        "title": "Memory Usage — Resident (RSS)",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 7},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [
          {"expr": "process_resident_memory_bytes{job=\"prometheus\"}", "legendFormat": "Prometheus RSS"},
          {"expr": "process_resident_memory_bytes{job=\"fastory-backend\"}", "legendFormat": "Backend RSS"}
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "bytes",
            "color": {"mode": "palette-classic"},
            "custom": {"fillOpacity": 25, "lineWidth": 2, "gradientMode": "scheme"}
          }
        }
      },
      {
        "id": 9,
        "title": "Network I/O — Bytes Received",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 15},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [
          {"expr": "rate(process_network_receive_bytes_total[5m])", "legendFormat": "{{job}} RX"},
          {"expr": "rate(process_network_transmit_bytes_total[5m])", "legendFormat": "{{job}} TX"}
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "Bps",
            "color": {"mode": "palette-classic"},
            "custom": {"fillOpacity": 15, "lineWidth": 2}
          }
        }
      },
      {
        "id": 10,
        "title": "Goroutines Over Time",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 15},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [
          {"expr": "go_goroutines{job=\"prometheus\"}", "legendFormat": "Prometheus"},
          {"expr": "go_goroutines{job=\"fastory-backend\"}", "legendFormat": "Backend"}
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"},
            "custom": {"fillOpacity": 10, "lineWidth": 2, "showPoints": "auto"}
          }
        }
      },
      {
        "id": 11,
        "title": "Heap Memory Allocation",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 23},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [
          {"expr": "go_memstats_heap_alloc_bytes", "legendFormat": "{{job}} heap alloc"},
          {"expr": "go_memstats_heap_inuse_bytes", "legendFormat": "{{job}} heap in-use"}
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "bytes",
            "color": {"mode": "palette-classic"},
            "custom": {"fillOpacity": 20, "lineWidth": 2, "gradientMode": "scheme"}
          }
        }
      },
      {
        "id": 12,
        "title": "Scrape Duration per Target",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 23},
        "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
        "targets": [
          {"expr": "scrape_duration_seconds", "legendFormat": "{{job}}"}
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "s",
            "color": {"mode": "palette-classic"},
            "custom": {"fillOpacity": 15, "lineWidth": 2, "showPoints": "auto", "pointSize": 4}
          }
        }
      }
    ],
    "schemaVersion": 39
  },
  "overwrite": true
}
'@

try {
    $r = Invoke-RestMethod -Uri "$base/api/dashboards/db" -Method Post -Headers $headers -Body $infraDashboard
    Write-Host "OK: $($r.url)"
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
    Write-Host $reader.ReadToEnd()
}
