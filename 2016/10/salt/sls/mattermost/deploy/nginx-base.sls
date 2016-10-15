firewalld:
  pkg.installed: []
  service.running:
    - enable: True
    - watch:
      - pkg: firewalld

nginx_unit_override:
  file.managed:
    - name: /etc/systemd/system/nginx.service
    - source: salt://mattermost/files/nginx.service
    - user: root
    - group: root
    - mode: 644
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: nginx_unit_override

nginx:
  pkgrepo.managed:
    - humanname: nginx repo
    - baseurl: http://nginx.org/packages/rhel/7/$basearch/
    - gpgcheck: False
    - enabled: True
  pkg.installed:
    - require:
      - pkgrepo: nginx
  service.running:
    - enable: True
    - require:
      - file: nginx_unit_override
      - pkg: nginx
    - watch:
      - file: mm_nginx_conf
      - cmd: nginx
  cmd.run:
    - name: mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
    - onlyif: test -f /etc/nginx/conf.d/default.conf

