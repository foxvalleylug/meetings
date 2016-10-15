certbot:
  file.managed:
    - name: /root/certbot-auto
    - source: {{ pillar['mattermost']['nginx']['certbot_url'] }}
    - source_hash: sha1={{ pillar['mattermost']['nginx']['certbot_sha1'] }}
    - user: root
    - group: root
    - mode: 755

letsencrypt_bundle:
  archive.extracted:
    - name: /etc
    - source: salt://mattermost/files/letsencrypt.tar.gz
    - archive_format: tar
    - user: root
    - group: root
    - if_missing: /etc/letsencrypt
