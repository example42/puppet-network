# == Definition: network::mroute
#
# Manages multiples routes on a single file
# Adds up to 2 files on RHEL:
# route-$name and route6-$name under /etc/sysconfig/networking-scripts 
# Adds 2 files on Debian:
# One under /etc/network/if-up.d and
# One in /etc/network/if-down.d
#
# === Parameters:
#
# [*routes*]
#   Required parameter. Must be an hash of network-gateway pairs.
#   Example:
#   network::mroute { 'bond1':
#     routes => {
#       '99.99.228.0/24'   => 'bond1',
#       '100.100.244.0/22' => '174.136.107.1',
#     }
#   }
#
#   ECMP route with two gateways example (works only with RedHat and Debian):
#
#   network::mroute { 'bond1':
#     routes => {
#       '99.99.228.0/24'   => 'bond1',
#       '100.100.244.0/22' => ['174.136.107.1', '174.136.107.2'],
#     }
#   }
#
# [*route_up_template*]
#   Template to use to manage route up setup. Default is defined according to
#   $::osfamily
#
# [*route6_template*]
#   Template to use to manage route6 up script. Used only on RedHat family.
#
# [*route_down_template*]
#   Template to use to manage route down script. Used only on Debian family.
#
# [*table*]
#   Optional parameter.
#   Route table to add routes in. Default - main route table.
#   Note, that all routes in mroute resource will be placed into supplied table.
#
# [*config_file_notify*]
#   String. Optional. Default: 'class_default'
#   Defines the notify argument of the created file.
#   The default special value uses the combination of the restart_all_nic and 
#   reload_command options. Set to undef to remove any notify, or set
#   the name(s) of the resources to notify
#
# [*restart_all_nic*]
#   Boolean. Default: false
#   Manages the way to apply interface creation/modification:
#   - If true, will trigger a restart of all network interfaces
#   - If false, will only start/restart this specific interface
#
# [*reload_command*]
#   String. Default: $::operatingsystem ? {
#    'CumulusLinux' => 'ifreload -a',
#     default       => "ifdown ${interface}; ifup ${interface}",
#   }
#   Defines the command(s) that will be used to reload a nic when restart_all_nic
#   is set to false
#
# === Actions:
#
# On Rhel
# Deploys the files route-$name and route6-$name in /etc/sysconfig/network-scripts
#
# On Debian
# Deploy 2 files 1 under /etc/network/if-up.d and 1 in /etc/network/if-down.d
#
# On Suse
# Deploys the file /etc/sysconfig/network/ifroute-$name.
#
define network::mroute (
  $routes,
  $interface           = $name,
  $config_file_notify  = 'class_default',
  $restart_all_nic     = false,
  $reload_command      = undef,
  $ensure              = 'present',
  $route_up_template   = undef,
  $route6_template     = undef,
  $route_down_template = undef,
  $table               = undef,
) {
  # Validate our arrays
  validate_hash($routes)
  $ipv6_routes = $routes.reduce({}) |$memo, $value| {
    if $value[0] =~ Stdlib::IP::Address::V6 {
      $memo + { $value[0] => $value[1], }
    } else {
      $memo
    }
  }
  $ipv4_routes = $routes.reduce({}) |$memo, $value| {
    if $value[0] =~ Stdlib::IP::Address::V4 {
      $memo + { $value[0] => $value[1], }
    } else {
      $memo
    }
  }

  include ::network
  $real_reload_command = $reload_command ? {
    undef => $::operatingsystem ? {
        'CumulusLinux' => 'ifreload -a',
        'RedHat'       => $::operatingsystemmajrelease ? {
          '8'     => "/usr/bin/nmcli con reload ; /usr/bin/nmcli device reapply ${interface}",
          default => "ifdown ${interface} --force ; ifup ${interface}",
        },
        default        => "ifdown ${interface} --force ; ifup ${interface}",
      },
    default => $reload_command,
  }
  if $restart_all_nic == false and $::kernel == 'Linux' {
    exec { "network_restart_route_${name}":
      command     => $real_reload_command,
      path        => '/sbin:/bin:/usr/sbin:/usr/bin',
      refreshonly => true,
    }
    $network_notify = "Exec[network_restart_route_${name}]"
  } else {
    $network_notify = $network::manage_config_file_notify
  }

  $real_config_file_notify = $config_file_notify ? {
    'class_default' => $network_notify,
    default         => $config_file_notify,
  }

  $real_route_up_template = $route_up_template ? {
    undef   => $::osfamily ? {
      'RedHat' => 'network/mroute-RedHat.erb',
      'Debian' => 'network/mroute_up-Debian.erb',
      'SuSE'   => 'network/mroute-SuSE.erb',
    },
    default =>  $route_up_template,
  }

  $real_route6_template = $route6_template ? {
    undef   => $::osfamily ? {
      'RedHat' => 'network/mroute6-RedHat.erb',
      default  => undef,
    },
    default =>  $route6_template,
  }

  $real_route_down_template = $route_down_template ? {
    undef   => $::osfamily ? {
      'Debian' => 'network/mroute_down-Debian.erb',
      default  => undef,
    },
    default =>  $route_down_template,
  }

  if $::osfamily == 'SuSE' {
    $networks = keys($routes)
    network::mroute::validate_gw { $networks:
      routes => $routes,
    }
  }

  # TODO: add support for other distros
  if $::osfamily != 'RedHat' and $table {
    notify {"table parameter in mroute has no effect on ${::osfamily}!":
      loglevel => warning,
    }
  }

  case $::osfamily {
    'RedHat': {
      unless $ipv4_routes.empty {
        file { "route-${name}":
          ensure  => $ensure,
          mode    => '0644',
          owner   => 'root',
          group   => 'root',
          path    => "/etc/sysconfig/network-scripts/route-${name}",
          content => template($real_route_up_template),
          notify  => $real_config_file_notify,
        }
      }
      unless $ipv6_routes.empty {
        file { "route6-${name}":
          ensure  => $ensure,
          mode    => '0644',
          owner   => 'root',
          group   => 'root',
          path    => "/etc/sysconfig/network-scripts/route6-${name}",
          content => template($real_route6_template),
          notify  => $real_config_file_notify,
        }
      }
    }
    'Debian': {
      file { "routeup-${name}":
        ensure  => $ensure,
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        path    => "/etc/network/if-up.d/z90-route-${name}",
        content => template($real_route_up_template),
        notify  => $real_config_file_notify,
      }
      file { "routedown-${name}":
        ensure  => $ensure,
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        path    => "/etc/network/if-down.d/z90-route-${name}",
        content => template($real_route_down_template),
        notify  => $real_config_file_notify,
      }
    }
    'SuSE': {
      file { "route-${name}":
        ensure  => $ensure,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        path    => "/etc/sysconfig/network/ifroute-${name}",
        content => template($real_route_up_template),
        notify  => $real_config_file_notify,
      }
    }
    default: { fail('Operating system not supported')  }
  }
}
