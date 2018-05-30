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
#   $metric    - optional
#   $mtu       - optional
#   $scope     - optional
#   $source    - optional
#   $table     - optional
#   $cidr      - optional
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
# Deploys 2 files under/etc/sysconfig/network-scripts/, route-$name and route6-$name
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
#     ipaddress => [ '192.168.2.0', '10.0.0.0', '::', ],
#     netmask   => [ '255.255.255.0', '255.0.0.0', '0', ],
#     gateway   => [ '192.168.1.1', '10.0.0.1', 'fd00::1', ],
#     family    => [ 'inet4', 'inet4', 'inet6', ],
#   }
#
# Note that for the familiy parameter, everything else than "inet6" will be written
# as an IPv4 route.
#
# A routing table can also be specified for the route:
#
#   network::route { 'eth1':
#     ipaddress => [ '192.168.3.0', ],
#     netmask   => [ '255.255.255.0', ],
#     gateway   => [ '192.168.3.1', ],
#     table     => [ 'vlan22' ],
#   }
#
# If adding routes to a routing table on an interface with multiple routes, it
# is necessary to specify false or 'main' for the table on the other routes.
# The 'main' routing table is where routes are added by default.
#
# The same applies if adding scope, source or gateway, i.e. false needs to be
# specified for those routes without values for those parameters, if defining
# multiple routes for the same interface.
#
# The first two routes in the following example are functionally equivalent to
# the routes added in the example above for bond2.
#
#   network::route { 'bond2':
#     ipaddress => [ '192.168.2.0', '10.0.0.0', '0.0.0.0', '192.168.3.0' ]
#     netmask   => [ '255.255.255.0', '255.0.0.0', '0.0.0.0', '255.255.255.0' ],
#     gateway   => [ '192.168.1.1', '10.0.0.1', '192.168.3.1', false ],
#     scope     => [ false, false, false, 'link', ],
#     source    => [ false, false, false, '192.168.3.10', ],
#     table     => [ false, false, 'vlan22' 'vlan22', ],
#   }
#
# The second two routes yield the following routes in table vlan22:
#
# # ip route show table vlan22
# default via 192.168.3.1 dev bond2
# 192.168.3.0/255.255.255.0 dev bond2 scope link src 192.168.3.10
#
# Normally the link level routing (192.168.3.0/255.255.255.0) is added
# automatically by the kernel when an interface is brought up. When using routing
# rules and routing tables, this does not happen, so this route must be added
# manually.
#
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
  $metric    = undef,
  $mtu       = undef,
  $scope     = undef,
  $source    = undef,
  $table     = undef,
  $cidr      = undef,
  $family    = [ 'inet4' ],
  $interface = $name,
  $ensure    = 'present'
) {
  # Validate our arrays
  validate_array($ipaddress)
  validate_array($netmask)

  if $gateway {
    validate_array($gateway)
  }

  if $metric {
    validate_array($metric)
  }

  if $mtu {
    validate_integer($mtu)
  }

  if $scope {
    validate_array($scope)
  }

  if $source {
    validate_array($source)
  }

  if $table {
    validate_array($table)
  }

  if $cidr {
    validate_array($cidr)
    $_cidr = $cidr
  } else {
    $_cidr = build_cidr_array($netmask)
  }

  if $family {
    validate_array($family)
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
      file { "route6-${name}":
        ensure  => $ensure,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        path    => "/etc/sysconfig/network-scripts/route6-${name}",
        content => template('network/route6-RedHat.erb'),
        notify  => $network::manage_config_file_notify,
      }
    }
    'Suse': {
      file { "ifroute-${name}":
        ensure  => $ensure,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        path    => "/etc/sysconfig/network/ifroute-${name}",
        content => template('network/route-Suse.erb'),
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
