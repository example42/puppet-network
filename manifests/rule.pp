# == Definition: network::rule
#
# Configures /etc/sysconfig/networking-scripts/rule-$name on RHEL
#
# === Parameters:
#
#   $iprule - required
#
# === Actions:
#
# On RHEL
# Deploys /etc/sysconfig/networking-scripts/rule-$name
#
# On Debian
# Deploys 2 files, 1 under /etc/network/if-up.d and 1 in /etc/network/if-down.d
#
# === Sample Usage:
#
#   network::rule { 'eth0':
#     iprule => ['from 192.168.22.0/24 lookup vlan22', ],
#   }
#
# === Authors:
#
# Marcus Furlong <furlongm@gmail.com>
#

define network::rule (
  $iprule,
  $interface = $name,
  $ensure    = 'present'
) {
  # Validate our arrays
  validate_array($iprule)

  include ::network

  case $::osfamily {
    'RedHat': {
      file { "rule-${interface}":
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0644',
        path    => "/etc/sysconfig/network-scripts/rule-${interface}",
        content => template('network/rule-RedHat.erb'),
        notify  => $network::manage_config_file_notify,
      }
    }
    'Suse': {
      file { "ifrule-${interface}":
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0644',
        path    => "/etc/sysconfig/network/ifrule-${interface}",
        content => template('network/rule-RedHat.erb'),
        notify  => $network::manage_config_file_notify,
      }
    }
    'Debian': {
      file { "ruleup-${name}":
        ensure  => $ensure,
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        path    => "/etc/network/if-up.d/z90-rule-${name}",
        content => template('network/rule_up-Debian.erb'),
        notify  => $network::manage_config_file_notify,
      }
      file { "ruledown-${name}":
        ensure  => $ensure,
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        path    => "/etc/network/if-down.d/z90-rule-${name}",
        content => template('network/rule_down-Debian.erb'),
        notify  => $network::manage_config_file_notify,
      }
    }
    default: { fail('Operating system not supported')  }
  }
} # define network::rule
