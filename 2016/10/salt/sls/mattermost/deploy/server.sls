{% set mm_version = pillar['mattermost']['server']['version'] %}
{% set mm_install_root = pillar['mattermost']['server']['install_root'] %}
{% set mm_install_dir = '/'.join((mm_install_root, mm_version)) %}
{% set mm_current_dir = '/'.join((mm_install_root, 'current')) %}
{% set mm_data_dir = '/'.join((mm_install_root, 'data')) %}
{% set mm_config_json = '/'.join((mm_install_dir, 'mattermost/config/config.json')) %}

{% set mm_system_user = pillar['mattermost']['server']['system_user'] %}
{% set mm_system_group = pillar['mattermost']['server']['system_group'] %}

mm_server_prereqs:
  pkg.installed:
    - pkgs:
      - tar
      - gzip

{{ mm_install_dir }}:
  archive.extracted:
    - source: https://releases.mattermost.com/{{ mm_version }}/mattermost-team-{{ mm_version }}-linux-amd64.tar.gz
    - source_hash: sha1={{ pillar['mattermost']['server']['archive_sha1'] }}
    - archive_format: tar
    - user: {{ mm_system_user }}
    - group: {{ mm_system_group }}
    - if_missing: {{ mm_install_dir }}
    - require:
      - user: {{ mm_system_user }}
      - group: {{ mm_system_group }}

/opt/mattermost/current:
  file.symlink:
    - target: {{ mm_install_dir }}
    - require:
      - archive: {{ mm_install_dir }}

mattermost_group:
  group.present:
    - name: {{ mm_system_group }}

mattermost_user:
  user.present:
    - name: {{ mm_system_user }}
    - gid_from_name: True
    - password: {{ pillar['mattermost']['server']['system_user_pass'] }}

{{ mm_data_dir }}:
  file.directory:
    - user: {{ mm_system_user }}
    - group: {{ mm_system_group }}
    - mode: 775
    - require:
      - user: {{ mm_system_user }}
      - group: {{ mm_system_group }}

{{ mm_config_json }}:
  file.serialize:
    - dataset:
        SqlSettings:
            DriverName: {{ pillar['mattermost']['server']['drivername'] }}
            DataSource: {{ pillar['mattermost']['server']['datasource'] }}
            DataSourceReplicas: []
            MaxIdleConns: 10
            MaxOpenConns: 10
            Trace: False
            AtRestEncryptKey: ""
    - formatter: json
    - merge_if_exists: True
    - user: {{ mm_system_user }}
    - group: {{ mm_system_group }}
    - mode: 644
    - require:
      - archive: {{ mm_install_dir }}

mm_service:
  file.managed:
    - name: /etc/systemd/system/mattermost.service
    - source: salt://mattermost/files/mattermost.service
    - user: root
    - group: root
    - mode: 644
  service.running:
    - name: mattermost
    - enable: True
    - watch:
      - file: mm_service
