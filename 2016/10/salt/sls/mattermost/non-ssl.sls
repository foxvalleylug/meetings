setup_postgres:
  salt.state:
    - tgt: mattermost
    - ssh: True
    - sls:
      - mattermost.deploy.database

setup_server:
  salt.state:
    - tgt: mattermost
    - ssh: True
    - sls:
      - mattermost.deploy.server
    - require:
      - salt: setup_postgres

setup_nginx:
  salt.state:
    - tgt: mattermost
    - ssh: True
    - sls:
      - mattermost.deploy.nginx-non-ssl
    - require:
      - salt: setup_server
