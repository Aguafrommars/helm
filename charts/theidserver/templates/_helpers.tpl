{{/*
Expand the name of the chart.
*/}}
{{- define "theidserver.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "theidserver.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name $.Values.nameOverride }}
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
{{- define "theidserver.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "theidserver.labels" -}}
helm.sh/chart: {{ include "theidserver.chart" . }}
{{ include "theidserver.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "theidserver.selectorLabels" -}}
app.kubernetes.io/name: {{ include "theidserver.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "theidserver.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "theidserver.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
define from subcharts
*/}}
{{- define "theidserver.mysql.fullname" -}}
{{- if $.Values.mysql.fullnameOverride }}
{{- $.Values.mysql.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "mysql" .Values.mysql.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "theidserver.redis.fullname" -}}
{{- if $.Values.redis.fullnameOverride }}
{{- $.Values.redis.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "redis" .Values.redis.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "theidserver.seq.fullname" -}}
{{- if .Values.seq.fullnameOverride }}
{{- .Values.seq.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "seq" .Values.seq.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create the connection string
*/}}
{{- define "theidserver.connectionString" -}}
{{- if not .Values.connectionString }}
{{- $name := required "The MySql mysql.auth.name is required" .Values.mysql.auth.name }}
{{- $user := required "The MySql mysql.auth.user is required" .Values.mysql.auth.user }}
{{- $pwd := required "The MySql mysql.auth.password is required" .Values.mysql.auth.password }}
{{- $host := (include "theidserver.mysql.fullname" .)}}
{{- if eq .Values.mysql.architecture "replication" }}
{{- printf "server=%s-primary;uid=%s;pwd=%s;database=%s" $host $user $pwd $name }}
{{- else }}
{{- printf "server=%s;uid=%s;pwd=%s;database=%s" $host $user $pwd $name }}
{{- end }}
{{- else }}
{{- print .Values.connectionString }}
{{- end }}
{{- end }}

{{/*
Create the seq url
*/}}
{{- define "theidserver.seqUrl" -}}
{{ $port := default 5341 .Values.seq.ingestion.service.port }}
{{- printf "http://%s:%d" (include "theidserver.seq.fullname" .) (int $port) }}
{{- end }}

{{/*
Create the redis connection string
*/}}
{{- define "theidserver.redis" -}}
{{ $port := default 6379 .Values.redis.master.service.ports.redis }}
{{ $pass := ternary (printf ",password=%s" .Values.redis.auth.password) "" .Values.redis.auth.enabled }}
{{- if eq .Values.redis.architecture "replication" -}}
{{- printf "%s-headless:%d%s" (include "theidserver.redis.fullname" .) (int $port) ($pass) }}
{{- else -}}
{{- printf "%s:%d%s" (include "theidserver.redis.fullname" .) (int $port) ($pass) }}
{{- end }}
{{- end }}

{{/*
Create the theidserver container init command
*/}}
{{- define "theidserver.init" -}}
{{- $cpSettings := "cp /usr/local/share/config/appsettings.json /app/appsettings.json; cp /usr/local/share/config/admin-appsettings.json /app/wwwroot/appsettings.json" }}
{{- $protectTls := "openssl pkcs12 -export -out /usr/local/share/ca-certificates/ssl.pfx -inkey /usr/local/share/certificates/tls.key -in /usr/local/share/certificates/tls.crt -password pass:$ASPNETCORE_Kestrel__Certificates__Default__Password" }}
{{- $protectDP := "openssl pkcs12 -export -out /usr/local/share/ca-certificates/dp.pfx -inkey /usr/local/share/certificates/dataProtection.key -in /usr/local/share/certificates/dataProtection.crt -password pass:$DataProtectionOptions__KeyProtectionOptions__X509CertificatePassword" }}
{{- $protectSK := "openssl pkcs12 -export -out /usr/local/share/ca-certificates/sk.pfx -inkey /usr/local/share/certificates/signingKey.key -in /usr/local/share/certificates/signingKey.crt -password pass:$IdentityServer__Key__KeyProtectionOptions__X509CertificatePassword" }}
{{- if .Values.ssl.ca.trust }}
{{- $trustCert := "cp /usr/local/share/certificates/ca.key /usr/local/share/ca-certificates/ca.key; cp /usr/local/share/certificates/ca.crt /usr/local/share/ca-certificates/ca.crt; chmod -R 644 /usr/local/share/ca-certificates/; update-ca-certificates" }}
{{- printf "%s; %s; %s; %s; %s" $cpSettings $protectTls $protectDP $protectSK $trustCert }}
{{- else }}
{{- printf "%s; %s; %s; %s" $cpSettings $protectTls $protectDP $protectSK }}
{{- end }}
{{- end }}