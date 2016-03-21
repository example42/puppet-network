# == Definition: network::route
#
# Based on https://github.com/razorsedge/puppet-network/ route.pp manifest.
# Configures /etc/sysconfig/networking-scripts/route-$name on Rhel
# Adds 2 files on Debian:
# One under /etc/network/if-up.d and
# One in /etc/network/if-down.d
#
# === Parameters:
#
#   $ipaddress - required
#   $netmask   - required
#   $gateway   - optional
#
# [*config_file_notify*]
#   String. Optional. Default: 'class_default'
#   Defines the notify argument of the created file.
#   The default special value implies the same behaviour of the main class
#   configuration file. Set to undef to remove any notify, or set
#   the name(s) of the resources to notify
#
#
# === Actions:
#
# On Rhel
# Deploys the file /etc/sysconfig/network-scripts/route-$name.
#
# On Debian
# Deploy 2 files 1 under /etc/network/if-up.d and 1 in /etc/network/if-down.d
#
# === Sample Usage:
#
#   network::route { 'eth0':
#     ipaddress => [ '192.168.17.0', ],
#     netmask   => [ '255.255.255.0', ],
#     gateway   => [ '192.168.17.250', ],
#   }
#
#   network::route { 'bond2':
#     ipaddress => [ '192.168.2.0', '10.0.0.0', ],
#     netmask   => [ '255.255.255.0', '255.0.0.0', ],
#     gateway   => [ '192.168.1.1', '10.0.0.1', ],
#   }
#
# A specifc routing table can also be specified for the route:
#
#   network::route { 'eth1':
#     ipaddress => [ '192.168.3.0', ],
#     netmask   => [ '255.255.255.0', ],
#     gateway   => [ '192.168.3.1', ],
#     table     => [ 'vlan22' ],
#   }
#
# If adding routes to specific routing tables on an interface with multiple
# routes, it is required to explicitly add the 'main' table to all other routes.
# The 'main' routing table is where routes are added by default.
#
#   network::route { 'bond2':
#     ipaddress => [ '192.168.2.0', '10.0.0.0', '192.168.3.0', ]
#     netmask   => [ '255.255.255.0', '255.0.0.0', '255.255.255.0', ],
#     gateway   => [ '192.168.1.1', '10.0.0.1', '192.168.3.1', ],
#     table     => [ 'main', 'main', 'vlan22' ],
#   }
#
# === Authors:
#
# Mike Arnold <mike@razorsedge.org>
# Riccardo Capecchi <riccio.cri@gmail.com>
#
# === Copyright:
#
# Copyright (C) 2011 Mike Arnold, unless otherwise noted.
#
define network::route (
  $ipaddress,
  $netmask,
  $gateway   = undef,
  $table     = undef,
  $interface = $name,
  $ensure    = 'present'
) {
  # Validate our arrays
  validate_array($ipaddress)
  validate_array($netmask)

  if $gateway {
    validate_array($gateway)
  }

  if $table {
    validate_array($table)
  }

  include ::network

  case $::osfamily {
    'RedHat': {
      file { "route-${name}":
        ensure  => $ensure,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        path    => "/etc/sysconfig/network-scripts/route-${name}",
        content => template('network/route-RedHat.erb'),
        notify  => $network::manage_config_file_notify,
      }
    }
    'Debian': {
      file { "routeup-${name}":
        ensure  => $ensure,
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        path    => "/etc/network/if-up.d/z90-route-${name}",
        content => template('network/route_up-Debian.erb'),
        notify  => $network::manage_config_file_notify,
      }
      file { "routedown-${name}":
        ensure  => $ensure,
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        path    => "/etc/network/if-down.d/z90-route-${name}",
        content => template('network/route_down-Debian.erb'),
        notify  => $network::manage_config_file_notify,
      }
    }
    default: { fail('Operating system not supported')  }
  }
} # define network::route
