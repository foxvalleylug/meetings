pg_repo:
  pkg.installed:
    - sources:
      - pgdg-redhat94: https://yum.postgresql.org/9.4/redhat/rhel-7.2-x86_64/pgdg-redhat94-9.4-3.noarch.rpm

pg_94:
  pkg.installed:
    - pkgs:
      - postgresql94-server
      - postgresql94-contrib
    - require:
      - pkg: pg_repo

# Refresh the modules since postgres state/exec module requires the postgresql
# data dir to be populated.
pg_initdb:
  cmd.run:
    - name: /usr/pgsql-9.4/bin/postgresql94-setup initdb
    - unless: test -n "`ls -A /var/lib/pgsql/9.4/data`"
    - require:
      - pkg: pg_94
    - refresh_modules: True

{% set pg_system_user = 'postgres' %}
{% set pg_pass = salt['config.option']('postgres.pass', 'unset') %}
{% set pg_hba_conf = '/var/lib/pgsql/9.4/data/pg_hba.conf' %}

{% set mm_db_name = pillar['mattermost']['database']['name'] %}
{% set mm_db_user = pillar['mattermost']['database']['user'] %}
{% set mm_db_pass = pillar['mattermost']['database']['pass'] %}

pg_service:
  service.running:
    - name: postgresql-9.4
    - enable: True
    - require:
      - cmd: pg_initdb
    - watch:
      - file: {{ pg_hba_conf }}
  file.managed:
    - name: {{ pg_hba_conf }}
    - source: salt://mattermost/files/pg_hba.conf
    - user: {{ pg_system_user }}
    - group: {{ pg_system_user }}
    - mode: 600
  cmd.run:
    - name: /bin/psql --dbname template1 -c "ALTER USER postgres with encrypted password '{{ pg_pass }}';"
    - user: {{ pg_system_user }}
    - onchanges:
      - service: pg_service

mattermost_db:
  postgres_user.present:
    - user: {{ pg_system_user }}
    - name: {{ mm_db_user }}
    - password: {{ mm_db_pass }}
    - login: True
    - require:
      - service: pg_service
  postgres_database.present:
    - user: {{ pg_system_user }}
    - name: {{ mm_db_name }}
    - require:
      - postgres_user: {{ mm_db_user }}
  postgres_privileges.present:
    - user: {{ pg_system_user }}
    - name: {{ mm_db_user }}
    - object_name: {{ mm_db_name }}
    - object_type: database
    - privileges:
      - ALL
    - require:
      - postgres_database: {{ mm_db_name }}
      - postgres_user: {{ mm_db_user }}
