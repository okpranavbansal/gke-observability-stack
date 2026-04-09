# GKE Observability Stack Architecture

## Overview

```mermaid
flowchart TD
    subgraph prd [prd-copilot namespace]
        Services[Application Pods\n23 services]
        Promtail[Promtail DaemonSet\nlog collector]
    end

    subgraph obs [observability namespace]
        subgraph metrics [Metrics Stack]
            Prometheus[Prometheus\nkube-prometheus-stack\n30d retention\n50Gi pd-ssd]
            Alertmanager[Alertmanager\nHA pair]
            NodeExporter[Node Exporter\nDaemonSet]
            KSM[kube-state-metrics]
        end

        subgraph logs [Log Stack]
            Loki[Loki\nscalable mode\nGCS backend]
            LokiGW[Loki Gateway\nnginx]
        end

        subgraph traces [Trace Stack]
            Tempo[Tempo\nGCS backend\n7d retention]
        end

        subgraph frontend [Frontend]
            Grafana[Grafana\nHA 2 replicas\nGCS session store]
        end
    end

    subgraph gcs [GCS Buckets]
        LokiChunks[acme-loki-chunks-prd]
        TempoBlocks[acme-tempo-traces-prd]
    end

    subgraph alerting [Alerting Destinations]
        PD[PagerDuty\nS1/S2 alerts]
        Slack[Slack\n#alerts channel]
    end

    Services -- metrics scraped by --> Prometheus
    NodeExporter -- host metrics --> Prometheus
    KSM -- k8s metrics --> Prometheus
    Services -- structured logs --> Promtail
    Promtail --> LokiGW --> Loki
    Services -- OTLP gRPC :4317 --> Tempo
    Loki --> LokiChunks
    Tempo --> TempoBlocks
    Prometheus -- alerts --> Alertmanager
    Alertmanager --> PD
    Alertmanager --> Slack
    Grafana -- queries --> Prometheus
    Grafana -- queries --> Loki
    Grafana -- queries --> Tempo
```

---

## Component Sizing

| Component | Replicas | CPU Request | Memory Request | Storage |
|-----------|----------|-------------|---------------|---------|
| Prometheus | 1 | 500m | 2Gi | 50Gi pd-ssd |
| Alertmanager | 2 | 100m | 256Mi | 1Gi pd-standard |
| Grafana | 2 | 250m | 512Mi | — (GCS session) |
| Loki (write) | 3 | 500m | 1Gi | — (GCS) |
| Loki (read) | 2 | 250m | 512Mi | — |
| Tempo | 1 | 500m | 1Gi | — (GCS) |
| Promtail | 1/node | 100m | 128Mi | — |

---

## Retention Policies

| Signal | prd | stg |
|--------|-----|-----|
| Metrics | 30 days | 7 days |
| Logs | 30 days (GCS lifecycle) | 7 days |
| Traces | 7 days | 3 days |

---

## Workload Identity Setup

All observability components use Workload Identity to access GCS — no static credentials.

```
Kubernetes SA: loki-sa (observability ns) → GCP SA: loki@prj-acme-prd.iam.gserviceaccount.com
  └─ roles/storage.objectAdmin on acme-loki-chunks-prd

Kubernetes SA: tempo-sa (observability ns) → GCP SA: tempo@prj-acme-prd.iam.gserviceaccount.com
  └─ roles/storage.objectAdmin on acme-tempo-traces-prd
```

See `terraform/workload-identity/main.tf`.

---

## Alerting Coverage

See `docs/alerting-rules.md` for the full list. Key categories:
1. **Infrastructure**: Node CPU/memory/disk, pod restarts
2. **Application**: HTTP error rate, P99 latency, unhealthy deployments
3. **Kafka**: Consumer lag, broker unavailability
4. **LLM**: First-token latency, Bedrock throttling
5. **Certificates**: Expiry < 30d, < 7d
6. **Error budgets**: Burn rate alerts (fast burn and slow burn)
