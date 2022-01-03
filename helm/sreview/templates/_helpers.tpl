{{- define "sreview.envvals" }}
envFrom:
- configMapRef:
    name: {{ .Release.Name }}-config
env:
- name: SREVIEWSECRET_NAME
  value: {{ .Release.Name }}-secret
{{- if .Values.use_internal_pg }}
- name: SREVIEW_DBICOMPONENTS
  value: "host password dbname user"
- name: SREVIEW_DBI_USER
  value: "postgres"
- name: SREVIEW_DBI_HOST
  value: {{ .Release.Name }}-postgresql-headless
- name: SREVIEW_DBI_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-postgresql
      key: postgresql-password
- name: SREVIEW_DBI_DBNAME
  value: "postgres"
{{- else }}
- name: SREVIEW_DBISTRING
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secret
      key: SREVIEW_DBISTRING
{{- end }}
{{- if .Values.use_internal_minio }}
- name: SREVIEW_S3_DEFAULT_ACCESSKEY
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-minio
      key: accesskey
- name: SREVIEW_S3_DEFAULT_SECRETKEY
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-minio
      key: secretkey
- name: SREVIEW_S3_DEFAULT_HOST
  value: {{ .Release.Name }}-minio:9000
- name: SREVIEW_S3_DEFAULT_SECURE
  value: "0"
{{- else }}
- name: SREVIEW_S3_ACCESS_CONFIG
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secret
      key: SREVIEW_S3_ACCESS_CONFIG
{{- end }}
- name: SREVIEW_ADMINPW
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secret
      key: SREVIEW_ADMINPW
- name: SREVIEW_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secret
      key: SREVIEW_API_KEY
{{- end }}
