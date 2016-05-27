# Completely ignore non-RHEL based systems
{% if salt['grains.get']('os_family') == 'RedHat' %}
{% from "epel/map.jinja" import epel with context %}

install_pubkey_epel:
  file.managed:
    - name: /etc/pki/rpm-gpg/{{ epel.key_name }}
    - source: {{ epel.key }}
    - source_hash:  {{ epel.key_hash }}

epel_release:
  pkg.installed:
    - sources:
      - epel-release: {{ epel.rpm }}
    - require:
      - file: install_pubkey_epel

set_pubkey_epel:
  file.replace:
    - append_if_not_found: True
    - name: /etc/yum.repos.d/epel.repo
    - pattern: '^\s*gpgkey=.*'
    - repl: 'gpgkey=file:///etc/pki/rpm-gpg/{{ epel.key_name }}'
    - require:
      - pkg: epel_release

set_gpg_epel:
  file.replace:
    - append_if_not_found: True
    - name: /etc/yum.repos.d/epel.repo
    - pattern: '^\s*gpgcheck=.*'
    - repl: 'gpgcheck=1'
    - require:
      - pkg: epel_release

{%   for entry in epel.disabled %}
disable_{{ entry }}:
  pkgrepo.managed:
    - name: {{ entry }}
    - enable: 0
{%   endfor %}
{%   for entry in epel.enabled %}
enable_{{ entry }}:
  pkgrepo.managed:
    - name: {{ entry }}
    - enable: 1
{%   endfor %}
{% endif %}
