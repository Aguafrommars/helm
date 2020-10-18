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
{{- define "theidserver.seq.fullname" -}}
{{- if $.Values.private.seq.fullnameOverride }}
{{- $.Values.private.seq.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "seq" .Values.private.seq.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "theidserver.private.fullname" -}}
{{- if $.Values.private.fullnameOverride }}
{{- $.Values.private.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "private" .Values.private.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create the seq url
*/}}
{{- define "theidserver.seqUrl" -}}
{{ $port := default 5341 .Values.private.seq.service.port }}
{{- printf "http://%s:%d" (include "theidserver.seq.fullname" .) (int $port) }}
{{- end }}

{{/*
Create the private url
*/}}
{{- define "theidserver.privateUrl" -}}
{{ $port := default 5443 .Values.private.service.port }}
{{- printf "https://%s:%d" (include "theidserver.private.fullname" .) (int $port) }}
{{- end }}

{{/*
Create the service url
*/}}
{{- define "theidserver.url" -}}
{{ $host := "localhost" }}
{{- if .Values.ingress.enabled }}
{{ with index .Values.ingress.hosts 0 }}
{{ $host = .host }}
{{- end }}
{{- $port := .Values.service.ports.https }}
{{- if eq 443 (int $port) }}
{{- printf "https://%s" $host }}
{{- else }}
{{- printf "https://%s:%d" $host (int $port) }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create the theidserver container init command
*/}}
{{- define "theidserver.init" -}}
{{- $cpSettings := "cp /usr/local/share/config/admin-appsettings.json /app/wwwroot/appsettings.json" }}
{{- $protectTls := "openssl pkcs12 -export -out /usr/local/share/ca-certificates/ssl.pfx -inkey /usr/local/share/certificates/ssl.key -in /usr/local/share/certificates/ssl.crt -password pass:$ASPNETCORE_Kestrel__Certificates__Default__Password" }}
{{- $protectDP := "openssl pkcs12 -export -out /usr/local/share/ca-certificates/dp.pfx -inkey /usr/local/share/certificates/dataProtection.key -in /usr/local/share/certificates/dataProtection.crt -password pass:$DataProtectionOptions__KeyProtectionOptions__X509CertificatePassword" }}
{{- $protectSK := "openssl pkcs12 -export -out /usr/local/share/ca-certificates/sk.pfx -inkey /usr/local/share/certificates/signingKey.key -in /usr/local/share/certificates/signingKey.crt -password pass:$IdentityServer__Key__KeyProtectionOptions__X509CertificatePassword" }}
{{- $trustPrivateCert := "" }}
{{- if .Values.private.ssl.ca.trust }}
{{- $trustPrivateCert = "; cp /usr/local/share/private-certificates/ca.key /usr/local/share/ca-certificates/private-ca.key; cp /usr/local/share/private-certificates/ca.crt /usr/local/share/ca-certificates/private-ca.crt" }}
{{- end }}
{{- $trustCert := "" }}
{{- if .Values.ssl.ca.trust }}
{{- $trustCert = "; cp /usr/local/share/certificates/ca.key /usr/local/share/ca-certificates/ca.key; cp /usr/local/share/certificates/ca.crt /usr/local/share/ca-certificates/ca.crt" }}
{{- end }}
{{- if or .Values.private.ssl.ca.trust .Values.ssl.ca.trust }}
{{- printf "%s; %s; %s; %s%s%s; chmod -R 644 /usr/local/share/ca-certificates/; update-ca-certificates" $cpSettings $protectTls $protectDP $protectSK $trustPrivateCert $trustCert }}
{{- else }}
{{- printf "%s; %s; %s; %s" $cpSettings $protectTls $protectDP $protectSK }}
{{- end }}
{{- end }}
