#
# = Class: network
#
# This class installs and manages network
#
#
# == Parameters
#
# [*gateway*]
#   String. Optional. Default: undef
#   The default gateway of your system
#
# [*hostname*]
#   String. Optional. Default: undef
#   The hostname of your system
#
# [*interfaces_hash*]
#   Hash. Default undef.
#   The complete interfaces configuration (nested) hash
#   Needs this structure:
#   - First level: Interface name
#   - Second level: Interface options (check network::interface for the
#     available options)
#   If an hash is provided here, network::interface defines are declared with:
#   create_resources("network::interface", $interfaces_hash)
#
# [*routes_hash*]
#   Hash. Default undef.
#   The complete routes configuration (nested) hash
#   If an hash is provided here, network::route defines are declared with:
#   create_resources("network::route", $routes_hash)
#
# [*mroutes_hash*]
#   Hash. Default undef.
#   An hash of multiple route to be applied
#   If an hash is provided here, network::mroute defines are declared with:
#   create_resources("network::mroute", $mroutes_hash)
#
# [*rules_hash*]
#   Hash. Default undef.
#   An hash of ip rules to be applied
#   If an hash is provided here, network::rules defines are declared with:
#   create_resources("network::rules", $rules_hash)
#
# [*tables_hash*]
#   Hash. Default undef.
#   An hash of routing tables to be applied
#   If an hash is provided here, network::routing_table defines are declared with:
#   create_resources("network::routing_table", $tables_hash)

# Refer to https://github.com/stdmod for official documentation
# on the stdmod parameters used
#
class network (

  $hostname                  = undef,

  $interfaces_hash           = undef,
  $routes_hash               = undef,
  $mroutes_hash              = undef,
  $rules_hash                = undef,
  $tables_hash               = undef,

  $hostname_file_template   = "network/hostname-${::osfamily}.erb",

  # Parameter used only on RedHat family
  $gateway                   = undef,
  $nozeroconf                = undef,
  $ipv6enable                = undef,

  # Stdmod commons
  $package_name              = undef,
  $package_ensure            = 'present',

  $service_restart_exec      = $::network::params::service_restart_exec,

  $config_file_path          = $::network::params::config_file_path,
  $config_file_require       = undef,
  $config_file_notify        = 'class_default',
  $config_file_source        = undef,
  $config_file_template      = undef,
  $config_file_content       = undef,
  $config_file_options_hash  = { } ,

  $config_file_per_interface = false,

  $config_dir_path           = $::network::params::config_dir_path,
  $config_dir_source         = undef,
  $config_dir_purge          = false,
  $config_dir_recurse        = true,

  $dependency_class          = undef,
  $my_class                  = undef,

  $monitor_class             = undef,
  $monitor_options_hash      = { } ,

  $firewall_class            = undef,
  $firewall_options_hash     = { } ,

  $scope_hash_filter         = '(uptime.*|timestamp)',

  $tcp_port                  = undef,
  $udp_port                  = undef,

  $hiera_merge               = false,

  ) inherits ::network::params {

  # Hiera import

  if( $hiera_merge == true ) {
    $hiera_interfaces_hash = hiera_hash("${module_name}::interfaces_hash",undef)
    $real_interfaces_hash = $hiera_interfaces_hash ? {
      undef   => $interfaces_hash,
      default => $hiera_interfaces_hash,
    }

    $hiera_routes_hash = hiera_hash('network::routes_hash',undef)
    $real_routes_hash = $hiera_routes_hash ? {
      undef   => $routes_hash,
      default => $hiera_routes_hash,
    }

    $hiera_mroutes_hash = hiera_hash('network::mroutes_hash',undef)
    $real_mroutes_hash = $hiera_mroutes_hash ? {
      undef   => $mroutes_hash,
      default => $hiera_mroutes_hash,
    }
    $hiera_rules_hash = hiera_hash('network::rules_hash',undef)
    $real_rules_hash = $hiera_rules_hash ? {
      undef   => $rules_hash,
      default => $hiera_rules_hash,
    }
    $hiera_tables_hash = hiera_hash('network::tables_hash',undef)
    $real_tables_hash = $hiera_tables_hash ? {
      undef   => $tables_hash,
      default => $hiera_tables_hash,
    }
  }
  else {
    $real_interfaces_hash = $interfaces_hash
    $real_routes_hash     = $routes_hash
    $real_mroutes_hash    = $mroutes_hash
    $real_rules_hash      = $rules_hash
    $real_tables_hash     = $tables_hash
  }


  # Class variables validation and management

  validate_bool($config_dir_recurse)
  validate_bool($config_dir_purge)
  if $config_file_options_hash { validate_hash($config_file_options_hash) }
  if $monitor_options_hash { validate_hash($monitor_options_hash) }
  if $firewall_options_hash { validate_hash($firewall_options_hash) }
  if $real_interfaces_hash { validate_hash($real_interfaces_hash) }
  if $real_routes_hash { validate_hash($real_routes_hash) }
  if $real_mroutes_hash { validate_hash($real_mroutes_hash) }
  if $real_tables_hash { validate_hash($real_tables_hash) }

  $config_file_owner          = $::network::params::config_file_owner
  $config_file_group          = $::network::params::config_file_group
  $config_file_mode           = $::network::params::config_file_mode

  $manage_config_file_content = $config_file_content ? {
    undef => $config_file_template ? {
      undef   => undef,
      default => template($config_file_template),
    },
    default => $config_file_content,
  }

  $manage_config_file_notify  = $config_file_notify ? {
    'class_default' => "Exec[${service_restart_exec}]",
    'undef'         => undef,
    ''              => undef,
    undef           => undef,
    default         => $config_file_notify,
  }

  $manage_hostname = pick($hostname, $::fqdn)

  if $package_ensure == 'absent' {
    $config_dir_ensure = absent
    $config_file_ensure = absent
  } else {
    $config_dir_ensure = directory
    $config_file_ensure = present
  }


  # Dependency class

  if $dependency_class {
    include $dependency_class
  }


  # Resources managed

  if $package_name {
    package { 'network':
      ensure => $package_ensure,
      name   => $package_name,
    }
  }

  if $config_file_path
  and $config_file_source
  or $manage_config_file_content {
    file { 'network.conf':
      ensure  => $config_file_ensure,
      path    => $config_file_path,
      mode    => $config_file_mode,
      owner   => $config_file_owner,
      group   => $config_file_group,
      source  => $config_file_source,
      content => $manage_config_file_content,
      notify  => $manage_config_file_notify,
      require => $config_file_require,
    }
  }

  if $config_dir_source {
    file { 'network.dir':
      ensure  => $config_dir_ensure,
      path    => $config_dir_path,
      source  => $config_dir_source,
      recurse => $config_dir_recurse,
      purge   => $config_dir_purge,
      force   => $config_dir_purge,
      notify  => $manage_config_file_notify,
      require => $config_file_require,
    }
  }

  # Command that triggers network restart
  exec { $service_restart_exec :
    command     => $service_restart_exec,
    alias       => 'network_restart',
    refreshonly => true,
    path        => '/bin:/sbin:/usr/bin:/usr/sbin',
  }

  # Create network interfaces from interfaces_hash, if present

  if $real_interfaces_hash {
    create_resources('network::interface', $real_interfaces_hash)
  }

  if $real_routes_hash {
    create_resources('network::route', $real_routes_hash)
  }

  if $real_mroutes_hash {
    create_resources('network::mroute', $real_mroutes_hash)
  }

  if $real_rules_hash {
    create_resources('network::rule', $real_rules_hash)
  }

  if $real_tables_hash {
    create_resources('network::routing_table', $real_tables_hash)
  }

  # Configure default gateway (On RedHat). Also hostname is set.
  if $::osfamily == 'RedHat'
  and $network::gateway {
    file { '/etc/sysconfig/network':
      ensure  => $config_file_ensure,
      mode    => $config_file_mode,
      owner   => $config_file_owner,
      group   => $config_file_group,
      content => template($network::hostname_file_template),
      notify  => $network::manage_config_file_notify,
    }
    case $::lsbmajdistrelease {
      '7': {
        exec { 'sethostname':
          command => "/usr/bin/hostnamectl set-hostname ${manage_hostname}",
          unless  => "/usr/bin/hostnamectl status | grep 'Static hostname: ${manage_hostname}'",
        }
      }
      default: {}
    }
  }

  # Configure hostname (On Debian)
  if $::osfamily == 'Debian'
  and $hostname {
    file { '/etc/hostname':
      ensure  => $config_file_ensure,
      mode    => $config_file_mode,
      owner   => $config_file_owner,
      group   => $config_file_group,
      content => template($hostname_file_template),
      notify  => $manage_config_file_notify,
    }
  }

  if $::osfamily == 'Suse' {
    if $hostname {
      file { '/etc/HOSTNAME':
        ensure  => $config_file_ensure,
        mode    => $config_file_mode,
        owner   => $config_file_owner,
        group   => $config_file_group,
        content => inline_template("<%= @manage_hostname %>\n"),
        notify  => Exec['sethostname'],
      }
      exec { 'sethostname':
        command => "/bin/hostname ${manage_hostname}",
        unless  => "/bin/hostname -f | grep ${manage_hostname}",
      }
    }
  }

  if $::osfamily == 'Solaris' {
    if $hostname {
      file { '/etc/nodename':
        ensure  => $config_file_ensure,
        mode    => $config_file_mode,
        owner   => $config_file_owner,
        group   => $config_file_group,
        content => inline_template("<%= @manage_hostname %>\n"),
        notify  => Exec['sethostname'],
      }
      exec { 'sethostname':
        command => "/usr/bin/hostname ${manage_hostname}",
        unless  => "/usr/bin/hostname | /usr/bin/grep ${manage_hostname}",
      }
    }
  }


  # Extra classes

  if $network::my_class {
    include $network::my_class
  }

  if $network::monitor_class {
    class { $network::monitor_class:
      options_hash => $network::monitor_options_hash,
      scope_hash   => {}, # TODO: Find a good way to inject class' scope
    }
  }

  if $firewall_class {
    class { $firewall_class:
      options_hash => $firewall_options_hash,
      scope_hash   => {},
    }
  }

}
