{{/*
_helpers.tpl — MedinovAI Command Center Helm Helpers
(c) 2026 Copyright MedinovAI. All Rights Reserved.
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "command-center.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "command-center.fullname" -}}
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
{{- define "command-center.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "command-center.labels" -}}
helm.sh/chart: {{ include "command-center.chart" . }}
{{ include "command-center.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
medinovai.health/tier: "2"
medinovai.health/compliance: "hipaa,gdpr"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "command-center.selectorLabels" -}}
app.kubernetes.io/name: {{ include "command-center.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: command-center
{{- end }}
