# Completely ignore non-RHEL based systems
{% if salt['grains.get']('os_family') == 'RedHat' %}
{% from "epel/map.jinja" import epel with context %}

install_pubkey_epel:
  file.managed:
    - name: /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL{{ '-' ~ salt['grains.get']('osmajorrelease') }}
    - source: {{ epel.pubkey }}
    - source_hash:  {{ epel.pubkey_hash }}

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
    - pattern: '^gpgkey=.*'
    - repl: "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL{{ '-' ~ salt['grains.get']('osmajorrelease') }}"
    - require:
      - pkg: epel_release

set_gpg_epel:
  file.replace:
    - append_if_not_found: True
    - name: /etc/yum.repos.d/epel.repo
    - pattern: 'gpgcheck=.*'
    - repl: 'gpgcheck=1'
    - require:
      - pkg: epel_release

{#{%   if salt['pillar.get']('epel:disabled', False) %}#}
{%     for entry in epel.disabled %}
disable_{{ entry }}:
  file.replace:
    - name: /etc/yum.repos.d/epel.repo
    - pattern: '\[{{ entry }}\](.*?)enabled=[01]'
    - repl: '[{{ entry }}]\1enabled=0'
    - flags: ['DOTALL']
{%     endfor %}
{#{%   else %}#}
{%     for entry in epel.enabled %}
enable_{{ entry }}:
  file.replace:
    - name: /etc/yum.repos.d/epel.repo
    - pattern: '\[{{ entry }}\](.*?)enabled=[01]'
    - repl: '[{{ entry }}]\1enabled=1'
    - flags: ['DOTALL']
{%     endfor %}
{#{%   endif %}#}

{%   if epel.testing %}
{%     for entry in epel.disabled %}
disable_{{ entry }}:
  file.replace:
    - name: /etc/yum.repos.d/epel-testing.repo
    - pattern: '\[{{ entry }}\](.*?)enabled=[01]'
    - repl: '[{{ entry }}]\1enabled=0'
    - flags: ['DOTALL']
{%     endfor %}
{%     for entry in epel.enabled %}
enable_{{ entry }}:
  file.replace:
    - name: /etc/yum.repos.d/epel-testing.repo
    - pattern: '\[{{ entry }}-testing\](.*?)enabled=[01]'
    - repl: '[{{ entry }}-testing]\1enabled=1'
    - flags: ['DOTALL']
{%     endfor %}
{%   endif %}

{% endif %}
