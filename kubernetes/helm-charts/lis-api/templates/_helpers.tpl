{{/*
MedinovAI LIS API - Helm Template Helpers
Common template functions for the LIS API Helm chart
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "lis-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "lis-api.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "lis-api.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "lis-api.labels" -}}
helm.sh/chart: {{ include "lis-api.chart" . }}
{{ include "lis-api.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: medinovai-platform
compliance/hipaa: {{ .Values.global.compliance.hipaa | default "true" | quote }}
compliance/iso-13485: {{ .Values.global.compliance.iso13485 | default "true" | quote }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "lis-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lis-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "lis-api.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "lis-api.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper image name
*/}}
{{- define "lis-api.image" -}}
{{- $registryName := .Values.image.registry -}}
{{- $repositoryName := .Values.image.repository -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- if .Values.global.imageRegistry }}
    {{- $registryName = .Values.global.imageRegistry -}}
{{- end -}}
{{- if .Values.image.digest }}
{{- printf "%s/%s@%s" $registryName $repositoryName .Values.image.digest -}}
{{- else }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- end -}}
{{- end }}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "lis-api.imagePullSecrets" -}}
{{- include "common.images.pullSecrets" (dict "images" (list .Values.image) "global" .Values.global) -}}
{{- end -}}

{{/*
Create a default fully qualified MySQL name.
*/}}
{{- define "lis-api.mysql.fullname" -}}
{{- printf "%s-%s" .Release.Name "mysql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified Redis name.
*/}}
{{- define "lis-api.redis.fullname" -}}
{{- printf "%s-%s" .Release.Name "redis" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Get the database connection string
*/}}
{{- define "lis-api.databaseConnectionString" -}}
{{- if .Values.externalDatabase.connectionString }}
{{- .Values.externalDatabase.connectionString }}
{{- else }}
{{- printf "Server=%s;Port=%s;Database=%s;User=%s;Password=%s;SslMode=Required" 
    (include "lis-api.mysql.fullname" .) 
    "3306" 
    (.Values.mysql.auth.database | default "LIS") 
    (.Values.mysql.auth.username | default "lis_app") 
    "${DB_PASSWORD}" }}
{{- end }}
{{- end }}

{{/*
Get the Redis connection string
*/}}
{{- define "lis-api.redisConnectionString" -}}
{{- if .Values.externalRedis.connectionString }}
{{- .Values.externalRedis.connectionString }}
{{- else }}
{{- printf "%s:6379,password=${REDIS_PASSWORD},ssl=false,abortConnect=false" (include "lis-api.redis.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Healthcare compliance labels
*/}}
{{- define "lis-api.complianceLabels" -}}
compliance.medinovai.com/hipaa: {{ .Values.global.compliance.hipaa | default "true" | quote }}
compliance.medinovai.com/iso-13485: {{ .Values.global.compliance.iso13485 | default "true" | quote }}
compliance.medinovai.com/gdpr: {{ .Values.global.compliance.gdpr | default "true" | quote }}
compliance.medinovai.com/audit-logging: {{ .Values.global.compliance.auditLogging | default "true" | quote }}
{{- end }}

{{/*
Security annotations for pods
*/}}
{{- define "lis-api.securityAnnotations" -}}
seccomp.security.alpha.kubernetes.io/pod: runtime/default
container.apparmor.security.beta.kubernetes.io/{{ .Chart.Name }}: runtime/default
{{- end }}
