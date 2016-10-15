{% set mm_database_host = salt['config.option']('postgres.host', '127.0.0.1') %}
{% set mm_database_port = salt['config.option']('postgres.port', 5432) %}
{% set mm_database_name = salt['config.option']('postgres.mm_database_name', 'default_name_if_option_not_set') %}
{% set mm_database_user = salt['config.option']('postgres.mm_database_user', 'default_user_if_option_not_set') %}
{% set mm_database_pass = salt['config.option']('postgres.mm_database_pass', 'default_pass_if_option_not_set') %}


mattermost:
  database:
    host: {{ mm_database_host }}
    port: {{ mm_database_port }}
    name: {{ mm_database_name }}
    user: {{ mm_database_user }}
    pass: {{ mm_database_pass }}
  server:
    version: '3.4.0'
    archive_sha1: bf2b7153ad1bb6fcbeb337f3a9a40f4adeda4938
    install_root: /opt/mattermost
    system_user: mattermost
    # I randomly generated the password that corresponds to this hash and have no idea what the actual password is.
    system_user_pass: '$6$lmLTQyhYZSKN74yT$lKdmkA2MHnTM5jsxo8w8uFe5iywZUtbZmPEiWyPMnIL05.Sqzoeqd.v2rtuqU0sdh2cggQBFOm/FMNt0YrEMm.'
    system_group: mattermost
    drivername: postgres
    datasource: 'postgres://{{ mm_database_user }}:{{ mm_database_pass }}@{{ mm_database_host }}:{{ mm_database_port }}/{{ mm_database_name }}?sslmode=disable&connect_timeout=10'
  nginx:
    certbot_url: https://dl.eff.org/certbot-auto
    certbot_sha1: e26e90aeffc5c084aff836d0b86a5d0c17a34f6b
