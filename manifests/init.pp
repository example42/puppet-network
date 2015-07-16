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
# Refer to https://github.com/stdmod for official documentation
# on the stdmod parameters used
#
class network (

  $hostname                  = undef,

  $interfaces_hash           = undef,

  $routes_hash               = undef,

  $hostname_file_template   = "network/hostname-${::osfamily}.erb",

  # Parameter used only on RedHat family
  $gateway                   = undef,
  $nozeroconf                = undef,
  $ipv6enable                = undef,

  # Stdmod commons
  $package_name              = undef,
  $package_ensure            = 'present',

  $service_restart_exec      = $network::params::service_restart_exec,

  $config_file_path          = $network::params::config_file_path,
  $config_file_require       = undef,
  $config_file_notify        = 'class_default',
  $config_file_source        = undef,
  $config_file_template      = undef,
  $config_file_content       = undef,
  $config_file_options_hash  = { } ,

  $config_file_per_interface = false,

  $config_dir_path           = $network::params::config_dir_path,
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

  ) inherits network::params {

  # Hiera import

  if( $hiera_merge ) {
    $hiera_interfaces_hash = hiera_hash("${module_name}::interfaces_hash",undef)
    $real_interfaces_hash = $hiera_interfaces_hash ? {
      undef   => $interfaces_hash,
      default => $hiera_interfaces_hash,
    }

    $hiera_routes_hash = hiera_hash("${module_name}::routes_hash",undef)
    $real_routes_hash = $hiera_routes_hash ? {
      undef   => $routes_hash,
      default => $hiera_routes_hash,
    }
  }
  else {
    $real_interfaces_hash = $interfaces_hash
    $real_routes_hash     = $routes_hash
  }


  # Class variables validation and management

  validate_bool($config_dir_recurse)
  validate_bool($config_dir_purge)
  if $config_file_options_hash { validate_hash($config_file_options_hash) }
  if $monitor_options_hash { validate_hash($monitor_options_hash) }
  if $firewall_options_hash { validate_hash($firewall_options_hash) }
  if $real_interfaces_hash { validate_hash($real_interfaces_hash) }
  if $real_routes_hash { validate_hash($real_routes_hash) }

  $config_file_owner          = $network::params::config_file_owner
  $config_file_group          = $network::params::config_file_group
  $config_file_mode           = $network::params::config_file_mode

  $manage_config_file_content = default_content($config_file_content, $config_file_template)

  $manage_config_file_notify  = $config_file_notify ? {
    'class_default' => "Exec[${network::service_restart_exec}]",
    'undef'         => undef,
    ''              => undef,
    undef           => undef,
    default         => $config_file_notify,
  }

  $manage_hostname = pickx($network::hostname, $::fqdn)

  if $package_ensure == 'absent' {
    $config_dir_ensure = absent
    $config_file_ensure = absent
  } else {
    $config_dir_ensure = directory
    $config_file_ensure = present
  }


  # Dependency class

  if $network::dependency_class {
    include $network::dependency_class
  }


  # Resources managed

  if $network::package_name {
    package { 'network':
      ensure => $network::package_ensure,
      name   => $network::package_name,
    }
  }

  if $network::config_file_path
  and $network::config_file_source
  or $network::manage_config_file_content {
    file { 'network.conf':
      ensure  => $network::config_file_ensure,
      path    => $network::config_file_path,
      mode    => $network::config_file_mode,
      owner   => $network::config_file_owner,
      group   => $network::config_file_group,
      source  => $network::config_file_source,
      content => $network::manage_config_file_content,
      notify  => $network::manage_config_file_notify,
      require => $network::config_file_require,
    }
  }

  if $network::config_dir_source {
    file { 'network.dir':
      ensure  => $network::config_dir_ensure,
      path    => $network::config_dir_path,
      source  => $network::config_dir_source,
      recurse => $network::config_dir_recurse,
      purge   => $network::config_dir_purge,
      force   => $network::config_dir_purge,
      notify  => $network::manage_config_file_notify,
      require => $network::config_file_require,
    }
  }

  # Command that triggers network restart
  exec { $network::service_restart_exec :
    command     => $network::service_restart_exec,
    alias       => 'network_restart',
    refreshonly => true,
    path        => '/bin:/sbin:/usr/bin:/usr/sbin',
  }

  # Create network interfaces from interfaces_hash, if present

  if $real_interfaces_hash {
    create_resources('network::interface', $real_interfaces_hash)
  }

  if $real_routes_hash {
    if $::osfamily == 'Suse' {
      file { '/etc/sysconfig/network/routes':
        ensure  => $network::config_file_ensure,
        mode    => $network::config_file_mode,
        owner   => $network::config_file_owner,
        group   => $network::config_file_group,
        content => template("network/route-${::osfamily}.erb"),
        notify  => $network::manage_config_file_notify,
      }
    } else {
      create_resources('network::route', $real_routes_hash)
    }
  }


  # Configure default gateway (On RedHat). Also hostname is set.
  if $::osfamily == 'RedHat'
  and $network::gateway {
    file { '/etc/sysconfig/network':
      ensure  => $network::config_file_ensure,
      mode    => $network::config_file_mode,
      owner   => $network::config_file_owner,
      group   => $network::config_file_group,
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
  and $network::hostname {
    file { '/etc/hostname':
      ensure  => $network::config_file_ensure,
      mode    => $network::config_file_mode,
      owner   => $network::config_file_owner,
      group   => $network::config_file_group,
      content => template($network::hostname_file_template),
      notify  => $network::manage_config_file_notify,
    }
  }

  if $::osfamily == 'Suse' {
    if $network::hostname {
      file { '/etc/HOSTNAME':
        ensure  => $network::config_file_ensure,
        mode    => $network::config_file_mode,
        owner   => $network::config_file_owner,
        group   => $network::config_file_group,
        content => inline_template("<%= @manage_hostname %>\n"),
        notify  => $network::sethostname,
      }
      exec { 'sethostname':
        command => "/bin/hostname ${manage_hostname}",
        unless  => "/bin/hostname -f | grep ${manage_hostname}",
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

  if $network::firewall_class {
    class { $network::firewall_class:
      options_hash => $network::firewall_options_hash,
      scope_hash   => {},
    }
  }

}

