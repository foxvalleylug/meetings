setup_postgres:
  salt.state:
    - tgt: mattermost.foxvalleylug.org
    - ssh: True
    - sls:
      - mattermost.deploy.database

setup_server:
  salt.state:
    - tgt: mattermost.foxvalleylug.org
    - ssh: True
    - sls:
      - mattermost.deploy.server
    - require:
      - salt: setup_postgres

setup_letsencrypt:
  salt.state:
    - tgt: mattermost.foxvalleylug.org
    - ssh: True
    - sls:
      - mattermost.deploy.letsencrypt
    - require:
      - salt: setup_server

setup_nginx:
  salt.state:
    - tgt: mattermost.foxvalleylug.org
    - ssh: True
    - sls:
      - mattermost.deploy.nginx-ssl
    - require:
      - salt: setup_letsencrypt
