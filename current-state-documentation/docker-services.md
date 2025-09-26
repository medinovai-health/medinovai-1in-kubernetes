# Docker Services Inventory
Generated: Fri Sep 26 08:22:05 EDT 2025

## Running Containers
```
NAMES                            IMAGE                                               STATUS                          PORTS
medinovai-analysis-metrics       prom/prometheus:latest                              Up 11 hours                     0.0.0.0:9090->9090/tcp, [::]:9090->9090/tcp
medinovai-analysis-dashboard     grafana/grafana:latest                              Up 11 hours                     0.0.0.0:3001->3000/tcp, [::]:3001->3000/tcp
medinovai-analysis-alerts        prom/alertmanager:latest                            Up 11 hours                     0.0.0.0:9093->9093/tcp, [::]:9093->9093/tcp
medinovai-analysis-system        medinovai-researchsuite-medinovai-analysis-system   Restarting (2) 16 seconds ago   
brave_wilson                     mcp/gitlab:latest                                   Up 13 hours                     
reverent_fermi                   mcp/gitlab:latest                                   Up 17 hours                     
lemonai-app                      hexdolemonai/lemon:latest                           Up 21 hours                     0.0.0.0:9505->5005/tcp, [::]:9505->5005/tcp
hello-app-nginx                  nginx:alpine                                        Up 20 hours                     0.0.0.0:8443->443/tcp, [::]:8443->443/tcp
hello-app-production             macstudio-optionb-hello-app                         Up 21 hours (unhealthy)         8080/tcp
hardcore_lamport                 mcp/gitlab:latest                                   Up 21 hours                     
medinovai-nginx                  nginx:alpine                                        Up 35 hours                     0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:443->443/tcp, [::]:443->443/tcp
medinovai-redis-cache            redis:7-alpine                                      Up 35 hours                     0.0.0.0:12603->6379/tcp, [::]:12603->6379/tcp
medinovai-qms-optimized          qualitymanagementsystem-qms-api                     Restarting (1) 35 seconds ago   
medinovai-healthllm-compliance   medinovai/healthllm:8.0.0-compliance                Up 46 hours (unhealthy)         0.0.0.0:12304-12306->12304-12306/tcp, [::]:12304-12306->12304-12306/tcp
medinovai-postgres-12308         postgres:16-alpine                                  Up 46 hours                     0.0.0.0:12308->5432/tcp, [::]:12308->5432/tcp
medinovai-redis-12310            redis:7-alpine                                      Up 46 hours                     0.0.0.0:12310->6379/tcp, [::]:12310->6379/tcp
medinovai-mongodb-12309          mongo:7.0                                           Up 46 hours                     0.0.0.0:12309->27017/tcp, [::]:12309->27017/tcp
nginx-proxy-manager              jc21/nginx-proxy-manager:latest                     Up 46 hours (healthy)           0.0.0.0:9590->80/tcp, [::]:9590->80/tcp, 0.0.0.0:9580->81/tcp, [::]:9580->81/tcp, 0.0.0.0:9591->443/tcp, [::]:9591->443/tcp
obsidian                         lscr.io/linuxserver/obsidian:latest                 Up 46 hours (healthy)           0.0.0.0:9500->3000/tcp, [::]:9500->3000/tcp, 0.0.0.0:9501->3001/tcp, [::]:9501->3001/tcp
medinovai-redis-restructured     redis:7-alpine                                      Up 46 hours                     0.0.0.0:12402->6379/tcp, [::]:12402->6379/tcp
```

## All Containers
```
NAMES                            IMAGE                                               STATUS                          PORTS
medinovai-analysis-metrics       prom/prometheus:latest                              Up 11 hours                     0.0.0.0:9090->9090/tcp, [::]:9090->9090/tcp
medinovai-analysis-dashboard     grafana/grafana:latest                              Up 11 hours                     0.0.0.0:3001->3000/tcp, [::]:3001->3000/tcp
medinovai-analysis-alerts        prom/alertmanager:latest                            Up 11 hours                     0.0.0.0:9093->9093/tcp, [::]:9093->9093/tcp
medinovai-analysis-system        medinovai-researchsuite-medinovai-analysis-system   Restarting (2) 16 seconds ago   
brave_wilson                     mcp/gitlab:latest                                   Up 13 hours                     
reverent_fermi                   mcp/gitlab:latest                                   Up 17 hours                     
lemonai-app                      hexdolemonai/lemon:latest                           Up 21 hours                     0.0.0.0:9505->5005/tcp, [::]:9505->5005/tcp
hello-app-nginx                  nginx:alpine                                        Up 20 hours                     0.0.0.0:8443->443/tcp, [::]:8443->443/tcp
hello-app-production             macstudio-optionb-hello-app                         Up 21 hours (unhealthy)         8080/tcp
hardcore_lamport                 mcp/gitlab:latest                                   Up 21 hours                     
medinovai-nginx                  nginx:alpine                                        Up 35 hours                     0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:443->443/tcp, [::]:443->443/tcp
medinovai-redis-cache            redis:7-alpine                                      Up 35 hours                     0.0.0.0:12603->6379/tcp, [::]:12603->6379/tcp
medinovai-qms-optimized          qualitymanagementsystem-qms-api                     Restarting (1) 36 seconds ago   
medinovai-healthllm-compliance   medinovai/healthllm:8.0.0-compliance                Up 46 hours (unhealthy)         0.0.0.0:12304-12306->12304-12306/tcp, [::]:12304-12306->12304-12306/tcp
medinovai-postgres-12308         postgres:16-alpine                                  Up 46 hours                     0.0.0.0:12308->5432/tcp, [::]:12308->5432/tcp
medinovai-redis-12310            redis:7-alpine                                      Up 46 hours                     0.0.0.0:12310->6379/tcp, [::]:12310->6379/tcp
medinovai-mongodb-12309          mongo:7.0                                           Up 46 hours                     0.0.0.0:12309->27017/tcp, [::]:12309->27017/tcp
nginx-proxy-manager              jc21/nginx-proxy-manager:latest                     Up 46 hours (healthy)           0.0.0.0:9590->80/tcp, [::]:9590->80/tcp, 0.0.0.0:9580->81/tcp, [::]:9580->81/tcp, 0.0.0.0:9591->443/tcp, [::]:9591->443/tcp
obsidian                         lscr.io/linuxserver/obsidian:latest                 Up 46 hours (healthy)           0.0.0.0:9500->3000/tcp, [::]:9500->3000/tcp, 0.0.0.0:9501->3001/tcp, [::]:9501->3001/tcp
medinovai-redis-restructured     redis:7-alpine                                      Up 46 hours                     0.0.0.0:12402->6379/tcp, [::]:12402->6379/tcp
```

## Docker Images
```
REPOSITORY                                          TAG                            SIZE      CREATED AT
dataofficer                                         latest                         4.98GB    2025-09-25 21:38:17 -0400 EDT
medinovai-researchsuite-medinovai-analysis-system   latest                         5.38GB    2025-09-25 21:31:53 -0400 EDT
medinovai/analysis-system                           4.2.0                          5.38GB    2025-09-25 21:30:10 -0400 EDT
medinovai/analysis-system                           latest                         5.38GB    2025-09-25 21:30:10 -0400 EDT
medinovai-dataofficer-dataofficer                   latest                         4.98GB    2025-09-25 21:28:34 -0400 EDT
qualitymanagementsystem-qms-api                     latest                         355MB     2025-09-24 21:29:07 -0400 EDT
qualitymanagementsystem-qms-standalone              latest                         1.02GB    2025-09-24 15:29:24 -0400 EDT
deployment-agent-orchestration                      latest                         325MB     2025-09-23 18:53:46 -0400 EDT
deployment-qms-core                                 latest                         325MB     2025-09-23 18:53:46 -0400 EDT
deployment-master-agent-dashboard                   latest                         80.3MB    2025-09-23 18:53:34 -0400 EDT
deployment-master-agent                             latest                         325MB     2025-09-23 18:52:38 -0400 EDT
deployment-document-service                         latest                         325MB     2025-09-23 18:52:38 -0400 EDT
deployment-analytics-service                        latest                         325MB     2025-09-23 18:52:38 -0400 EDT
deployment-notification-service                     latest                         325MB     2025-09-23 18:52:38 -0400 EDT
deployment-training-service                         latest                         325MB     2025-09-23 18:52:38 -0400 EDT
medinovai-qms-standalone                            latest                         969MB     2025-09-23 16:46:17 -0400 EDT
medinovai/healthllm                                 8.0.0-compliance               1.1GB     2025-09-23 11:51:49 -0400 EDT
medinovai/healthllm                                 8.0.0-mongodb-fixed            1.1GB     2025-09-23 11:43:27 -0400 EDT
medinovai/healthllm                                 8.0.0-all-apis                 1.1GB     2025-09-23 11:40:49 -0400 EDT
medinovai/healthllm                                 8.0.0-complete-apis            1.1GB     2025-09-23 11:35:14 -0400 EDT
medinovai/healthllm                                 8.0.0-self-contained           1.1GB     2025-09-23 11:13:11 -0400 EDT
medinovai/healthllm                                 8.0.0-final                    1.1GB     2025-09-23 11:01:13 -0400 EDT
medinovai/healthllm                                 8.0.0-complete                 1.1GB     2025-09-23 10:59:53 -0400 EDT
medinovai/healthllm                                 8.0.0-postgres-mongodb-fixed   1.1GB     2025-09-23 10:58:30 -0400 EDT
medinovai/healthllm                                 8.0.0-postgres-mongodb         1.1GB     2025-09-23 10:57:03 -0400 EDT
medinovai/healthllm                                 8.0.0-fixed                    816MB     2025-09-21 21:13:01 -0400 EDT
medinovai/healthllm                                 8.0.0                          816MB     2025-09-21 19:57:20 -0400 EDT
lscr.io/linuxserver/obsidian                        latest                         4.72GB    2025-09-21 07:50:59 -0400 EDT
docker-medinovai-restructured                       latest                         1.83GB    2025-09-20 18:10:56 -0400 EDT
docker-medinovai-restructure-test                   latest                         1.06GB    2025-09-20 17:40:17 -0400 EDT
medinovai-platform                                  self-sufficient                7.35GB    2025-09-19 17:26:13 -0400 EDT
medinovai-healthllm-medinovai                       latest                         5.71GB    2025-09-19 13:59:12 -0400 EDT
medinovai/system                                    latest                         5.71GB    2025-09-19 13:56:00 -0400 EDT
medinovai/consensus-orchestrator                    latest                         640MB     2025-09-17 15:11:07 -0400 EDT
medinovai/developer-agent                           latest                         640MB     2025-09-17 15:10:55 -0400 EDT
medinovai/architect-agent                           latest                         616MB     2025-09-17 15:10:14 -0400 EDT
ngrok-autosalespro-backend                          latest                         820MB     2025-09-09 18:08:49 -0400 EDT
medinovai/api                                       latest                         641MB     2025-09-09 17:56:32 -0400 EDT
medinovai-security-policy-engine                    latest                         673MB     2025-09-09 17:45:03 -0400 EDT
medinovai-security-tenant-onboarding                latest                         344MB     2025-09-09 17:45:01 -0400 EDT
medinovai-security-ollama-service                   latest                         322MB     2025-09-09 17:44:58 -0400 EDT
medinovai-security-audit-service                    latest                         210MB     2025-09-09 17:44:52 -0400 EDT
medinovai-security-token-validator                  latest                         225MB     2025-09-09 17:44:52 -0400 EDT
postgres                                            15                             650MB     2025-09-08 16:04:25 -0400 EDT
postgres                                            15-alpine                      387MB     2025-09-08 16:04:25 -0400 EDT
postgres                                            16-alpine                      390MB     2025-09-08 16:04:25 -0400 EDT
mongo                                               7.0                            1.07GB    2025-09-08 16:03:49 -0400 EDT
minio/minio                                         latest                         228MB     2025-09-07 14:44:27 -0400 EDT
macstudio-optionb-hello-app                         latest                         236MB     2025-09-05 19:37:51 -0400 EDT
ollama/ollama                                       latest                         5.55GB    2025-09-04 12:43:42 -0400 EDT
timescale/timescaledb                               latest-pg16                    1.4GB     2025-09-02 08:25:39 -0400 EDT
timescale/timescaledb                               latest-pg15                    1.69GB    2025-09-02 08:20:03 -0400 EDT
hapiproject/hapi                                    latest                         1.02GB    2025-08-27 15:25:05 -0400 EDT
nginx                                               alpine                         80.2MB    2025-08-13 12:34:01 -0400 EDT
grafana/grafana                                     latest                         906MB     2025-08-12 05:09:48 -0400 EDT
python                                              3.11-slim                      212MB     2025-08-08 14:20:34 -0400 EDT
prom/prometheus                                     latest                         423MB     2025-07-14 12:46:37 -0400 EDT
jc21/nginx-proxy-manager                            latest                         1.58GB    2025-07-09 17:37:16 -0400 EDT
redis                                               7-alpine                       61.4MB    2025-07-06 12:51:58 -0400 EDT
hexdolemonai/lemon                                  latest                         4.82GB    2025-07-04 22:59:32 -0400 EDT
hexdolemonai/lemon-runtime-sandbox                  latest                         5.97GB    2025-06-20 03:02:01 -0400 EDT
mcp/gitlab                                          latest                         251MB     2025-06-16 15:22:59 -0400 EDT
prom/alertmanager                                   latest                         106MB     2025-03-07 10:10:33 -0500 EST
quay.io/keycloak/keycloak                           24.0                           731MB     2025-02-18 10:11:10 -0500 EST
neo4j                                               5.23-community                 818MB     2024-08-22 07:51:04 -0400 EDT
clickhouse/clickhouse-server                        23.8                           1.31GB    2024-08-20 06:06:54 -0400 EDT
traefik                                             v3.0                           216MB     2024-07-02 17:51:36 -0400 EDT
neo4j                                               5.15-community                 791MB     2024-01-17 04:15:19 -0500 EST
registry                                            2                              36.1MB    2023-10-02 14:42:41 -0400 EDT
confluentinc/cp-kafka                               7.5.0                          1.35GB    2023-08-18 17:15:01 -0400 EDT
confluentinc/cp-zookeeper                           7.5.0                          1.35GB    2023-08-18 17:13:09 -0400 EDT
grafana/grafana                                     10.0.0                         427MB     2023-07-24 10:17:03 -0400 EDT
prom/prometheus                                     v2.45.0                        320MB     2023-06-23 11:54:21 -0400 EDT
elasticsearch                                       8.11.0                         10.3kB    1969-12-31 19:00:00 -0500 EST
kibana                                              8.11.0                         353MB     1969-12-31 19:00:00 -0500 EST
docker.elastic.co/elasticsearch/elasticsearch       8.11.0                         454MB     1969-12-31 19:00:00 -0500 EST
```

## Docker Networks
```
NETWORK ID     NAME                                         DRIVER    SCOPE
f3e70b64d392   bridge                                       bridge    local
67d4c59a03e5   host                                         host      local
66236ef09bdc   macstudio-optionb_default                    bridge    local
37ada2ba04c1   medinovai-healthllm_medinovai-network        bridge    local
812985b75929   medinovai-researchsuite_medinovai-analysis   bridge    local
51d80910b262   medinovai-restructured-network               bridge    local
d5d4cc20eda1   none                                         null      local
98fd02ac1c08   obsidian-docker_obsidian-network             bridge    local
9e68522a1b76   qualitymanagementsystem_qms-network          bridge    local
```

## Docker Volumes
```
DRIVER    VOLUME NAME
local     2f5b8f594026e8a7fc34c4e37595256158eaf4f57a6a3be8a3c348306ad2d13d
local     343a30586ab137adeef79db1ae9c1ec698d618cff881ca34f06689c7a0729dd4
local     7107af93e74e83ccc8049f832e9086b2aa50c6d3d92bc7015a8ef7946feaa7c5
local     99437f6667fb742257366c0ac415d558795400677c64cee937fdb11b9b0bf4d0
local     a7dcc5c293bd245de24d94a1d0444b63925f22b19443f3db5a7b8735e64fd7b9
local     c52605abc05df7b0b47c2df87440a3e691abe6e55119dadbe364b8c801239f52
local     dd62145ec5af9d111704fbc320e3bc864ba18e7d585ee2811cafc4835310adb6
local     deployment_elasticsearch_data
local     deployment_grafana_data
local     deployment_minio_data
local     deployment_ollama_data
local     deployment_postgres_data
local     deployment_prometheus_data
local     deployment_redis_data
local     docker_grafana_data
local     docker_medinovai_sqlite_data
local     docker_prometheus_data
local     grafana_data
local     medinovai-data-services_clickhouse_data
local     medinovai-data-services_elasticsearch_data
local     medinovai-data-services_grafana_data
local     medinovai-data-services_kafka1_data
local     medinovai-data-services_minio_data
local     medinovai-data-services_mongodb_primary_data
local     medinovai-data-services_postgres_data
local     medinovai-data-services_prometheus_data
local     medinovai-data-services_redis_master_data
local     medinovai-data-services_zookeeper_data
local     medinovai-dataofficer_postgres_data
local     medinovai-healthllm_mongodb_data
local     medinovai-healthllm_ollama_data
local     medinovai-healthllm_postgres_data
local     medinovai-healthllm_redis_data
local     medinovai-ollama-models
local     medinovai-qms-backups
local     medinovai-qms-certs
local     medinovai-qms-config
local     medinovai-qms-data
local     medinovai-qms-logs
local     medinovai-researchsuite_alertmanager-data
local     medinovai-researchsuite_analysis-dashboard-data
local     medinovai-researchsuite_analysis-logs
local     medinovai-researchsuite_analysis-reports
local     medinovai-researchsuite_analysis-results
local     medinovai-researchsuite_prometheus-data
local     medinovai-security_keycloak_data
local     medinovai-security_ollama_data
local     medinovai-security_postgres_data
local     medinovai-security_redis_data
local     minio_data
local     ngrok_postgres_data
local     postgres_data
local     qualitymanagementsystem_grafana_data
local     qualitymanagementsystem_neo4j_data
local     qualitymanagementsystem_neo4j_import
local     qualitymanagementsystem_neo4j_logs
local     qualitymanagementsystem_postgresql_data
local     qualitymanagementsystem_prometheus_data
local     qualitymanagementsystem_redis-data
local     qualitymanagementsystem_redis_data
local     qualitymanagementsystem_timescaledb_data
local     registry-data
```

## Docker System Information
```
Client:
 Version:    28.3.3
 Context:    default
 Debug Mode: false
 Plugins:
  ai: Docker AI Agent - Ask Gordon (Docker Inc.)
    Version:  v1.9.11
    Path:     /Users/dev1/.docker/cli-plugins/docker-ai
  buildx: Docker Buildx (Docker Inc.)
    Version:  v0.27.0-desktop.1
    Path:     /Users/dev1/.docker/cli-plugins/docker-buildx
  cloud: Docker Cloud (Docker Inc.)
    Version:  v0.4.21
    Path:     /Users/dev1/.docker/cli-plugins/docker-cloud
  compose: Docker Compose (Docker Inc.)
    Version:  v2.39.2-desktop.1
    Path:     /Users/dev1/.docker/cli-plugins/docker-compose
  debug: Get a shell into any image or container (Docker Inc.)
    Version:  0.0.42
    Path:     /Users/dev1/.docker/cli-plugins/docker-debug
  desktop: Docker Desktop commands (Docker Inc.)
    Version:  v0.2.0
    Path:     /Users/dev1/.docker/cli-plugins/docker-desktop
  extension: Manages Docker extensions (Docker Inc.)
    Version:  v0.2.31
    Path:     /Users/dev1/.docker/cli-plugins/docker-extension
  init: Creates Docker-related starter files for your project (Docker Inc.)
    Version:  v1.4.0
    Path:     /Users/dev1/.docker/cli-plugins/docker-init
  mcp: Docker MCP Plugin (Docker Inc.)
    Version:  v0.15.0
    Path:     /Users/dev1/.docker/cli-plugins/docker-mcp
  model: Docker Model Runner (EXPERIMENTAL) (Docker Inc.)
    Version:  v0.1.39
    Path:     /Users/dev1/.docker/cli-plugins/docker-model
  sbom: View the packaged-based Software Bill Of Materials (SBOM) for an image (Anchore Inc.)
    Version:  0.6.0
    Path:     /Users/dev1/.docker/cli-plugins/docker-sbom
  scout: Docker Scout (Docker Inc.)
    Version:  v1.18.3
    Path:     /Users/dev1/.docker/cli-plugins/docker-scout

Server:
 Containers: 20
  Running: 18
  Paused: 0
  Stopped: 2
 Images: 76
 Server Version: 28.3.3
 Storage Driver: overlayfs
  driver-type: io.containerd.snapshotter.v1
 Logging Driver: json-file
 Cgroup Driver: cgroupfs
 Cgroup Version: 2
 Plugins:
  Volume: local
  Network: bridge host ipvlan macvlan null overlay
  Log: awslogs fluentd gcplogs gelf journald json-file local splunk syslog
 CDI spec directories:
  /etc/cdi
  /var/run/cdi
 Discovered Devices:
  cdi: docker.com/gpu=webgpu
 Swarm: inactive
 Runtimes: io.containerd.runc.v2 runc
 Default Runtime: runc
 Init Binary: docker-init
 containerd version: 05044ec0a9a75232cad458027ca83437aae3f4da
 runc version: v1.2.5-0-g59923ef
 init version: de40ad0
 Security Options:
  seccomp
   Profile: builtin
  cgroupns
 Kernel Version: 6.10.14-linuxkit
 Operating System: Docker Desktop
 OSType: linux
 Architecture: aarch64
 CPUs: 24
 Total Memory: 7.651GiB
 Name: docker-desktop
 ID: 02b86e31-6241-458a-ad87-36f0c5194b57
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
 HTTP Proxy: http.docker.internal:3128
 HTTPS Proxy: http.docker.internal:3128
 No Proxy: hubproxy.docker.internal
 Labels:
  com.docker.desktop.address=unix:///Users/dev1/Library/Containers/com.docker.docker/Data/docker-cli.sock
 Experimental: false
 Insecure Registries:
  hubproxy.docker.internal:5555
  ::1/128
  127.0.0.0/8
 Live Restore Enabled: false
```
