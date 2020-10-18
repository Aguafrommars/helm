{{/*
Expand the name of the chart.
*/}}
{{- define "private.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "private.fullname" -}}
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
{{- define "private.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "private.labels" -}}
helm.sh/chart: {{ include "private.chart" . }}
{{ include "private.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "private.selectorLabels" -}}
app.kubernetes.io/name: {{ include "private.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "private.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "private.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
define from subcharts
*/}}
{{- define "private.mysql.fullname" -}}
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

{{- define "private.redis.fullname" -}}
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

{{- define "private.seq.fullname" -}}
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
{{- define "private.connectionString" -}}
{{- if not .Values.mysql.connectionString }}
{{- $name := required "The MySql private.mysql.db.name is required" .Values.mysql.db.name }}
{{- $user := required "The MySql private.mysql.db.user is required" .Values.mysql.db.user }}
{{- $pwd := required "The MySql private.mysql.db.password is required" .Values.mysql.db.password }}
{{- printf "server=%s;uid=%s;pwd=%s;database=%s" (include "private.mysql.fullname" .) $user $pwd $name }}
{{- else}}
{{- print .Values.mysql.connectionString }}
{{- end }}
{{- end }}

{{/*
Create the seq url
*/}}
{{- define "private.seqUrl" -}}
{{ $port := default 5341 .Values.seq.service.port }}
{{- printf "http://%s:%d" (include "private.seq.fullname" .) (int $port) }}
{{- end }}

{{/*
Create the redis connection string
*/}}
{{- define "private.redis" -}}
{{ $port := default 6379 .Values.redis.service.port }}
{{- printf "%s:%d" (include "private.redis.fullname" .) (int $port) }}
{{- end }}

{{/*
Create the private container init command
*/}}
{{- define "private.init" -}}
{{- $cpSettings := "cp /usr/local/share/config/admin-appsettings.json /app/wwwroot/appsettings.json" }}
{{- $protectTls := "openssl pkcs12 -export -out /usr/local/share/ca-certificates/ssl.pfx -inkey /usr/local/share/certificates/ssl.key -in /usr/local/share/certificates/ssl.crt -password pass:$ASPNETCORE_Kestrel__Certificates__Default__Password" }}
{{- $protectDP := "openssl pkcs12 -export -out /usr/local/share/ca-certificates/dp.pfx -inkey /usr/local/share/certificates/dataProtection.key -in /usr/local/share/certificates/dataProtection.crt -password pass:$DataProtectionOptions__KeyProtectionOptions__X509CertificatePassword" }}
{{- $protectSK := "openssl pkcs12 -export -out /usr/local/share/ca-certificates/sk.pfx -inkey /usr/local/share/certificates/signingKey.key -in /usr/local/share/certificates/signingKey.crt -password pass:$IdentityServer__Key__KeyProtectionOptions__X509CertificatePassword" }}
{{- if .Values.ssl.ca.trust }}
{{- $trustCert := "cp /usr/local/share/certificates/ca.key /usr/local/share/ca-certificates/ca.key; cp /usr/local/share/certificates/ca.crt /usr/local/share/ca-certificates/ca.crt; chmod -R 644 /usr/local/share/ca-certificates/; update-ca-certificates" }}
{{- printf "%s; %s; %s; %s; %s" $cpSettings $protectTls $protectDP $protectSK $trustCert }}
{{- else }}
{{- printf "%s; %s; %s; %s" $cpSettings $protectTls $protectDP $protectSK }}
{{- end }}
{{- end }}
