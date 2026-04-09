# Alerting Rules Reference

All rules are implemented as `PrometheusRule` CRDs in the `observability` namespace.  
They map to `alertmanager.yaml` routes: `critical` → PagerDuty, `warning` → Slack.

---

## Infrastructure Alerts

```yaml
groups:
  - name: infrastructure
    rules:
      - alert: NodeHighCPU
        expr: |
          (1 - avg by (node) (rate(node_cpu_seconds_total{mode="idle"}[5m]))) * 100 > 85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Node {{ $labels.node }} CPU > 85%"

      - alert: NodeHighMemory
        expr: |
          (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 > 85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Node {{ $labels.instance }} memory > 85%"

      - alert: NodeDiskPressure
        expr: |
          (1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 > 80
        for: 5m
        labels:
          severity: warning

      - alert: NodeDiskCritical
        expr: |
          (1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 > 90
        for: 2m
        labels:
          severity: critical
```

---

## Application Alerts

```yaml
  - name: application
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{namespace="prd-copilot",status=~"5.."}[5m]))
          /
          sum(rate(http_requests_total{namespace="prd-copilot"}[5m])) > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Error rate > 1%"

      - alert: HighP99Latency
        expr: |
          histogram_quantile(0.99,
            sum(rate(http_request_duration_seconds_bucket{namespace="prd-copilot"}[5m]))
            by (le, app)
          ) > 3
        for: 5m
        labels:
          severity: warning

      - alert: PodRestartingFrequently
        expr: increase(kube_pod_container_status_restarts_total{namespace="prd-copilot"}[10m]) > 5
        for: 0m
        labels:
          severity: warning

      - alert: DeploymentReplicasMismatch
        expr: |
          kube_deployment_spec_replicas{namespace="prd-copilot"}
          != kube_deployment_status_replicas_available{namespace="prd-copilot"}
        for: 15m
        labels:
          severity: critical
```

---

## Kafka Alerts

```yaml
  - name: kafka
    rules:
      - alert: KafkaConsumerLagHigh
        expr: kafka_consumer_group_lag_sum > 10000
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Consumer group {{ $labels.group }} lag > 10k on {{ $labels.topic }}"

      - alert: KafkaConsumerLagCritical
        expr: kafka_consumer_group_lag_sum > 100000
        for: 5m
        labels:
          severity: critical

      - alert: KafkaConsumerLagGrowing
        expr: |
          rate(kafka_consumer_group_lag_sum[15m]) > 100
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Consumer lag is growing at {{ $value | humanize }} msgs/sec"
```

---

## LLM Alerts

```yaml
  - name: llm
    rules:
      - alert: LLMFirstTokenLatencyHigh
        expr: |
          histogram_quantile(0.95,
            sum(rate(llm_first_token_latency_seconds_bucket[5m])) by (le)
          ) > 5
        for: 5m
        labels:
          severity: warning

      - alert: BedrockThrottling
        expr: rate(llm_bedrock_errors_total{error_type="ThrottlingException"}[5m]) > 0.1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Bedrock throttling rate > 0.1 req/s — check account quota"
```

---

## Error Budget Burn Rate Alerts

```yaml
  - name: error-budget
    rules:
      - alert: ErrorBudgetBurnFast
        expr: |
          (sum(rate(http_requests_total{status=~"5..",namespace="prd-copilot"}[1h]))
          / sum(rate(http_requests_total{namespace="prd-copilot"}[1h])))
          / 0.001 > 14.4
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Fast error budget burn — monthly budget exhausted in < 1 hour at this rate"

      - alert: ErrorBudgetBurnSlow
        expr: |
          (sum(rate(http_requests_total{status=~"5..",namespace="prd-copilot"}[6h]))
          / sum(rate(http_requests_total{namespace="prd-copilot"}[6h])))
          / 0.001 > 1
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "Slow error budget burn — budget will be exhausted before month end"
```

---

## Certificate Expiry Alerts

```yaml
  - name: certificates
    rules:
      - alert: CertificateExpiringWarning
        expr: ssl_certificate_expiry_seconds < 30 * 24 * 3600
        for: 1h
        labels:
          severity: warning

      - alert: CertificateExpiringCritical
        expr: ssl_certificate_expiry_seconds < 7 * 24 * 3600
        for: 0m
        labels:
          severity: critical
```
