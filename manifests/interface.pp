# A description of what this defined type does
#
# @summary A short summary of the purpose of this defined type.
#
# @example
#   network::interface { 'namevar': }
define network::interface (
  Boolean $enable                  = true,
  Enum['present','absent'] $ensure = 'present',

  String $template                 = "network/interface/${::osfamily}.epp",
  Optional[String] $config_path    = undef,

  Boolean $enable_dhcp             = false,

  String $interface                = $title,
  String $description              = "Interface $title",

  Optional[Stdlib::IP::Address::V4] $ipv4_address   = undef,
  Optional[Stdlib::IP::Address::V4] $ipv4_netmask   = undef,
  Optional[Stdlib::IP::Address::V4] $ipv4_broadcast = undef,

  Optional[Stdlib::IP::Address::V6] $ipv6_address = undef,
  Optional[Stdlib::IP::Address::V6] $ipv6_netmask = undef,

  Hash $extra_settings              = {},
  Optional[String] $extra_header    = undef,
  Optional[String] $extra_footer    = undef,
  Boolean $use_default_settings     = true,

  Array $os_features                = ['check_link_down','auto'],

  Hash $options                    = {},
  Boolean $restart_all_nic         = true,
  Optional[String]$reload_command  = undef,

  Boolean $manage_prerequisites    = true,
  Boolean $suppress_warnings       = false,
) {

  ### Define variables
  # Build configuration settings hash
  case fact('os.osfamily') {
    'RedHat': {
      $os_settings = {
        DEVICE        => $interface,
        NM_CONTROLLED => 'no',
        IPADDR        => $ipv4_address,
        IPV6ADDR      => $ipv6_address,
      }
      if 'check_link_down' in $os_features {
        $os_footer = @("EOF")
          check_link_down() {
            return 1;
          }
          |- EOF
      } else {
        $os_footer = ''
      }
      $os_header = ''
    }
    'Debian': {
      $os_settings = {}
      $os_header = "${stanza} ${interface} ${family} ${method}"
      $os_footer = ''
    }
    'SuSE': {
      $os_settings = {
      }
      $os_header = ''
      $os_footer = ''
    }
    default: {}
  }


  # $settings variable is used in templates
  if $use_default_settings {
    $settings = delete_undef_values($os_settings + $extra_settings)
    $header = $os_header + $extra_header
    $footer = $os_footer + $extra_footer
  } else {
    $settings = delete_undef_values($extra_settings)
    $header = $extra_header
    $footer = $extra_footer
  }
  # Content used in interface configuration file
  $template_type=$template[-4,4]
  case $template_type {
    '.epp': {
      $content = epp($template,$settings,$header,$footer)
    }
    '.erb': {
      $content = template($template)
    }
    default: {
      # If no known extension is present, we treat $template as an erb template
      $content = template($template)
    }
  }
  # Configuration file path
  case fact('os.family') {
    'RedHat': {
      $config_file_path = pick($config_path,"/etc/sysconfig/network-scripts/ifcfg-${title}")
    }
    'Suse': {
      $config_file_path = pick($config_path,"/etc/sysconfig/network/ifcfg-${title}")
    }
    'Debian': {
      if fact('os.name') == 'CumulusLinux' {
        $config_file_path = pick($config_path,"/etc/network/interfaces.d/${title}")
      } else {
        $config_file_path = pick($config_path,"/etc/network/interfaces.d/${title}.cfg")
      }
    }
    'Solaris': {
      $config_file_path = pick($config_path,"/etc/hostname.${title}")
    }
  }

  # Define how to restart network service
  $network_notify = pick($reload_command, $::network::manage_config_file_notify)


  ### Manage configurations
  case fact('os.name') {

    # On RedHat family we manage "/etc/sysconfig/network-scripts/ifcfg-${title}"
    'RedHat', 'CentOS', 'Scientific', 'OracleLinux','Fedora': {
      # Configuration
      file { $config_file_path:
        ensure  => $ensure,
        content => $content,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        notify  => $network_notify,
      }
    }

    # On Suse family we manage "/etc/sysconfig/network/ifcfg-${title}"
    'SLES', 'OpenSuSE': {
      # Prerequisites
      if $manage_prerequisites
      and has_key($settings,'VLAN_ID')
      and !defined(Package['vlan']) {
        package { 'vlan':
          ensure => 'present',
        }
        Package['vlan'] -> File[$config_file_path]
      }
      if $manage_prerequisites
      and has_key($settings,'BRIDGE')
      and !defined(Package['bridge-utils']) {
        package { 'bridge-utils':
          ensure => 'present',
        }
        Package['bridge-utils'] -> File[$config_file_path]
      }
      # Configuration
      file { $config_file_path:
        ensure  => $ensure,
        content => $content,
        mode    => '0600',
        owner   => 'root',
        group   => 'root',
        notify  => $network_notify,
      }
    }

    # On Debian family we manage "/etc/network/interfaces.d/${title}.cfg"
    # or lines in /etc/sysconfig/network according to the value of
    # $::network::config_file_per_interface
    'Debian', 'Ubuntu', 'LinuxMint': {
      # Prerequisites
      if $manage_prerequisites
      and has_key($settings,'vlan-raw-device')
      and versioncmp('9.0', $::operatingsystemrelease) >= 0
      and !defined(Package['vlan']) {
        package { 'vlan':
          ensure => 'present',
        }
      }
      # Configuration
      if $::network::config_file_per_interface {
        # Scenario with a file per interface
        if ! defined(File['/etc/network/interfaces.d']) {
          file { '/etc/network/interfaces.d':
            ensure => 'directory',
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
          }
        }
        file { $config_file_path:
          ensure  => $ensure,
          content => $content,
          notify  => $network_notify,
        }
        if ! defined(File_line['config_file_per_interface']) {
          file_line { 'config_file_per_interface':
            ensure => $ensure,
            path   => '/etc/network/interfaces',
            line   => 'source /etc/network/interfaces.d/*.cfg',
            notify => $network_notify,
          }
        }
      } else {
        # Scenario with everything configured in /etc/network/interfaces
        if ! defined(Concat['/etc/network/interfaces']) {
          concat { '/etc/network/interfaces':
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            notify => $network_notify,
          }
        }
        concat::fragment { "interface-${title}":
          target  => '/etc/network/interfaces',
          content => $content,
          order   => pick($options['order'], 50),
        }

        if ! defined(Network::Interface['lo']) {
          network::interface { 'lo':
            address => '127.0.0.1',
            method  => 'loopback',
            options => { 'order' => '05' },
          }
        }
      }
    }

    # On Cumulus we manage "/etc/network/interfaces.d/${name}"
    # and line addon_scripts_support=1 in /etc/network/ifupdown2/ifupdown2.conf
    'CumulusLinux': {
      # Configuration
      file { $config_file_path:
        ensure  => $ensure,
        content => $content,
        notify  => $network_notify,
      }
      if ! defined(File_line['config_file_per_interface']) {
        file_line { 'config_file_per_interface':
          ensure => $ensure,
          path   => '/etc/network/ifupdown2/ifupdown2.conf',
          line   => 'addon_scripts_support=1',
          match  => 'addon_scripts_suppor*',
          notify => $network_notify,
        }
      }
    }

    # On Solaris we manage "/etc/hostname.${title}"
    # ipadm exec, host entry and network service
    'Solaris': {
      # Configuration
      if $::operatingsystemrelease == '5.11' {
        if ! defined(Service['svc:/network/physical:nwam']) {
          service { 'svc:/network/physical:nwam':
            ensure => stopped,
            enable => false,
          }
        }
        Service['svc:/network/physical:nwam']
        -> Service['svc:/network/physical:default']
        -> Exec["create ipaddr ${title}"]
        -> File[$config_file_path]
      }
      case $::operatingsystemmajrelease {
        '11','5': {
          if $enable_dhcp {
            $create_ip_command = "ipadm create-addr -T dhcp ${interface}/dhcp"
            $show_ip_command = "ipadm show-addr ${interface}/dhcp"
          } else {
            $create_ip_command = "ipadm create-addr -T static -a ${ipv4_address}/${ipv4_netmask} ${interface}/v4static"
            $show_ip_command = "ipadm show-addr ${interface}/v4static"
          }
        }
        default: {
          $create_ip_command = 'true '
          $show_ip_command = 'true '
        }
      }
      exec { "create ipaddr ${title}":
        command => $create_ip_command,
        unless  => $show_ip_command,
        path    => '/bin:/sbin:/usr/sbin:/usr/bin:/usr/gnu/bin',
      }
      file { $config_file_path:
        ensure  => $ensure,
        content => $content,
        require => Exec["create ipaddr ${title}"],
      }
      host { $::fqdn:
        ensure       => present,
        ip           => $ipv4_address,
        host_aliases => [$::hostname],
        require      => File[$config_file_path],
      }
      if ! defined(Service['svc:/network/physical:default']) {
        service { 'svc:/network/physical:default':
          ensure    => running,
          enable    => true,
        }
      }
      Service['svc:/network/physical:default'] ~> File[$config_file_path]
      Service['svc:/network/physical:default'] ~> Exec["create ipaddr ${interface}"]
    }

    # Other OS not supported
    default: {
      if ! $suppress_warnings {
        alert("${::operatingsystem} not supported. Nothing done here. Set $suppress_warnings to true to disable this message")
      }
    }
  }

}
