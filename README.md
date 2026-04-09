# GKE Observability Stack
> Full observability stack on GKE: Prometheus + Grafana + Loki + Tempo with Workload Identity and Kustomize overlays.

![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white) ![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white) ![Loki](https://img.shields.io/badge/Loki-F46800?style=flat&logo=grafana&logoColor=white) ![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform&logoColor=white) ![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat&logo=helm&logoColor=white)

![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white) ![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white) ![Loki](https://img.shields.io/badge/Loki-F46800?style=flat&logo=grafana&logoColor=white) ![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform&logoColor=white) ![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat&logo=helm&logoColor=white)

Helm values + Terraform for deploying a full observability stack on GKE:
**Prometheus + Grafana + Loki + Tempo** with Workload Identity, Kustomize overlays, and sample dashboards.

Fork this repo and adapt to your GKE project.

---

## Architecture

```mermaid
flowchart TD
    subgraph gke [GKE Cluster]
        subgraph obs [observability namespace]
            Prom[Prometheus\nkube-prometheus-stack]
            Grafana[Grafana\nDashboards + Alerts]
            Loki[Loki\nLog Aggregation]
            Tempo[Tempo\nDistributed Tracing]
            Promtail[Promtail\nLog Shipper DaemonSet]
        end

        subgraph apps [Application Namespaces]
            App1[prd-copilot\nworkloads]
            App2[stg-copilot\nworkloads]
        end
    end

    subgraph storage [GCS Backends]
        LokiGCS[GCS: loki-chunks-bucket]
        TempoGCS[GCS: tempo-traces-bucket]
    end

    subgraph external [External]
        Confluent[Confluent Cloud\nKafka Metrics]
        PagerDuty[PagerDuty\nAlert Routing]
    end

    App1 -- metrics scrape --> Prom
    App2 -- metrics scrape --> Prom
    Promtail -- logs --> Loki
    App1 -- traces OTLP --> Tempo
    Prom -- query --> Grafana
    Loki -- query --> Grafana
    Tempo -- query --> Grafana
    Loki -- chunks --> LokiGCS
    Tempo -- traces --> TempoGCS
    Prom -- alertmanager --> PagerDuty
    Confluent -- JMX exporter --> Prom
```

---

## Stack Versions

| Component | Chart | Version |
|-----------|-------|---------|
| kube-prometheus-stack | prometheus-community/kube-prometheus-stack | 58.x |
| Loki | grafana/loki | 6.x |
| Tempo | grafana/tempo-distributed | 1.x |
| Grafana (included in kube-prometheus-stack) | — | 10.x |

---

## Repository Structure

```
gke-observability-stack/
├── README.md
├── terraform/
│   ├── gke-cluster/          # GKE cluster provisioning (optional)
│   └── workload-identity/    # GCP SA + WI binding for monitoring
├── helm/
│   └── values/
│       ├── prometheus.yaml
│       ├── loki.yaml
│       ├── tempo.yaml
│       └── grafana-dashboards.yaml
├── kustomize/
│   ├── base/
│   └── overlays/
│       ├── stg/
│       └── prd/
├── dashboards/
│   ├── gke-cluster-overview.json
│   ├── kafka-consumer-lag.json
│   ├── llm-service-latency.json
│   └── ecs-to-gke-migration.json
└── docs/
    ├── architecture.md
    └── alerting-rules.md
```

---

## Quick Start

```bash
# 1. Create GCP SA + Workload Identity binding
cd terraform/workload-identity
terraform init && terraform apply

# 2. Install kube-prometheus-stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n observability --create-namespace \
  -f helm/values/prometheus.yaml

# 3. Install Loki
helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade --install loki grafana/loki \
  -n observability \
  -f helm/values/loki.yaml

# 4. Install Tempo
helm upgrade --install tempo grafana/tempo-distributed \
  -n observability \
  -f helm/values/tempo.yaml

# 5. Import dashboards
kubectl apply -k kustomize/overlays/prd
```

## Author

**Pranav Bansal** — AI Infrastructure & SRE Engineer

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://linkedin.com/in/okpranavbansal)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat&logo=github&logoColor=white)](https://github.com/okpranavbansal)