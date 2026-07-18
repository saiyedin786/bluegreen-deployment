{{- define "blue-green-app.name" -}}
blue-green-app
{{- end }}

{{- define "blue-green-app.fullname" -}}
{{ .Release.Name }}
{{- end }}