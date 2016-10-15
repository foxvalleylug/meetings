include:
  - mattermost.deploy.nginx-base

mm_nginx_conf:
  file.managed:
    - name: /etc/nginx/conf.d/mattermost-ssl.conf
    - source: salt://mattermost/files/mattermost-ssl.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx

remove_mm_non_ssl_conf:
  file.absent:
    - name: /etc/nginx/conf.d/mattermost.conf
    - watch_in:
      - service: nginx

open_ports:
  firewalld.present:
    - name: public
    - ports:
      - 22/tcp
      - 80/tcp
      - 443/tcp
    - masquerade: True
    - require:
      - service: nginx
