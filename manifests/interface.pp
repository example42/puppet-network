# This define manages network interfaces on different operating systems.
# It provides some default configurations that can be overridden via relevant 
# parameters.
#
# @summary A define to manage network interfaces
#
# @example Configure an interface to use DHCP
#   network::interface { 'eth0':
#     enable_dhcp                => true,
#   }
#
# @example Configure an interface with a given IP address
#   network::interface { 'eth0':
#     ipv4_address => 10.42.42.42,
#     ipv4_netmask => 255.255.255.0,
#   }
#
# @param ensure If to create or remove the relevant configuration file.
# @param template The epp or erb template to use for the interface configuration
#   file. Default is automatically defined based on $::osfamily,
# @param config_path The path of the interface configuration file.
#   Default is automatically defined based on the Operating System.
# @param enable_dhcp If to configure the interface to use dhcp.
# @param interface The name of the interface to use. Default value is the $title of
#   the define. Can be set explicitly in case different title names have to
#   used.
# @param description A free text description to use, where applicable, to describe
#  the interface. It has no real effect on the interface configuration.
# @param ipv4_address The optional IPv4 address of the interface.
# @param ipv4_netmask The optional netmask of the IPv4 address.
# @param ipv4_network The optional IPv4 network address.
# @param ipv4_broadcast The optional IPv4 broadcast address.
# @param ipv6_address The optional IPv6 address of the interface.
# @param ipv6_netmask The optional netmask of the IPv6 address.
# @param ipv6_network The optional IPv6 network address.
# @param mtu The interface Maximum Transmission Unit (in bytes).
# @param mac The (optional) interface MAC address.
# @param redhat_extra_settings A free hash of custom settings to
#  add to the interface configuration. Used only on redhat family nodes.
# @param redhat_extra_header A custom free text to add as header
#  to the interface configuration file on RedHat family nodes.
# @param redhat_extra_footer A custom free text to add as footer
#  to the interface configuration file on RedHat family nodes.
# @param debian_extra_settings Equivalent of redhat_extra_settings for Debian osfamily.
# @param debian_extra_header Equivalent of redhat_extra_header for Debian osfamily.
# @param debian_extra_footer Equivalent of redhat_extra_footer for Debian osfamily.
# @param suse_extra_settings Equivalent of redhat_extra_settings for Suse osfamily.
# @param suse_extra_header Equivalent of redhat_extra_header for Suse osfamily.
# @param suse_extra_footer Equivalent of redhat_extra_footer for Suse osfamily.
# @param solaris_extra_settings Equivalent of redhat_extra_settings for Solaris.
# @param solaris_extra_header Equivalent of redhat_extra_header for Solaris.
# @param solaris_extra_footer Equivalent of redhat_extra_footer for Solaris.
# @param use_default_settings If to use some default settings also based on $os_features
#   to correctly configure interface files. They can be overridden via the
#   osfamily extra_settings.
# @param os_features Some features which affect the default_settings.
# @param config_file_notify The Resource to trigger when a configuration
#   change occurs. Default is what is se in $:::network::config_file_notify
# @param manage_prerequisites If to automatically manage prerequisite resources
#   like packages when needed by the interface type
# @suppress_warnings If not avoid to display notify warnings for unsupported OS.
define network::interface (
  Enum['present','absent'] $ensure                  = 'present',
  Boolean $enable                                   = true,
  Boolean $use_netplan                              = lookup('network::use_netplan',Boolean,first,false),

  String $template                                  = "network/interface/${::osfamily}.epp",
  Optional[String] $config_path                     = undef,


  String $interface                                 = $title,
  String $description                               = "Interface ${title}",

  Boolean                           $ipv4_dhcp      = false,
  Optional[Stdlib::IP::Address::V4] $ipv4_address   = undef,
  Optional[Stdlib::IP::Address::V4] $ipv4_netmask   = undef,
  Optional[Stdlib::IP::Address::V4] $ipv4_network   = undef,
  Optional[Stdlib::IP::Address::V4] $ipv4_broadcast = undef,
  Optional[Stdlib::IP::Address::V4] $ipv4_gateway   = undef,
  Optional[Integer]                 $ipv4_mtu       = undef,

  Boolean                           $ipv6_dhcp      = false,
  Optional[Stdlib::IP::Address::V6] $ipv6_address   = undef,
  Optional[Stdlib::IP::Address::V6] $ipv6_netmask   = undef,
  Optional[Stdlib::IP::Address::V6] $ipv6_network   = undef,
  Optional[Stdlib::IP::Address::V6] $ipv6_gateway   = undef,
  Optional[Integer]                 $ipv6_mtu       = undef,

  Optional[Integer] $mac                            = undef,
  Boolean $mac_override                             = false,

  Hash $redhat_extra_settings                       = {},
  Optional[String] $redhat_extra_header             = undef,
  Optional[String] $redhat_extra_footer             = undef,

  Hash $debian_extra_settings                       = {},
  Optional[String] $debian_extra_header             = undef,
  Optional[String] $debian_extra_footer             = undef,

  Hash $suse_extra_settings                         = {},
  Optional[String] $suse_extra_header               = undef,
  Optional[String] $suse_extra_footer               = undef,

  Hash $solaris_extra_settings                      = {},
  Optional[String] $solaris_extra_header            = undef,
  Optional[String] $solaris_extra_footer            = undef,

  Boolean $use_default_settings                     = true,

  Array $os_features                                = ['check_link_down','auto'],

  Variant[Undef,Resource,String] $config_file_notify = 'class_default',
  Boolean $config_file_per_interface                = true,

  Boolean $manage_prerequisites                     = true,
  Boolean $suppress_warnings                        = false,
) {

  case fact('os.family') {
    'RedHat': {
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
      $os_settings = {
        'ONBOOT'    => $enable ? {
          true  => 'yes',
          false => 'yes',
        },
        'BOOTPROTO' => $ipv4_dhcp ? {
          true  => 'dhcp',
          false => 'none',
        },
        'DEVICE'    => $interface,
        'IPADDR'    => $ipv4_address,
        'NETWORK'   => $ipv4_network,
        'NETMASK'   => $ipv4_netmask,
        'BROADCAST' => $ipv4_broadcast,
        'GATEWAY'   => $ipv4_gateway,
        'MTU'       => $ipv4_mtu,
        'HWADDR'    => $mac_override ? {
          true    => undef,
          default => $mac,
        },
        'MACADDR'   => $mac_override ? {
          true    => $mac,
          default => undef,
        },
        'DHCPV6C'   => $ipv6_dhcp ? {
          true  => 'yes',
          false => undef,
        },
        'IPV6ADDR'  => $ipv6_address,
        'IPV6MTU'   => $ipv6_mtu,
        'IPV6INIT'  => $ipv6_dhcp ? {
          true  => 'yes',
          false => $ipv6_address ? {
            undef   => undef,
            default => 'yes',
          },
        },
      }
      $extra_settings = $redhat_extra_settings
      $extra_header = $redhat_extra_header
      $extra_footer = $redhat_extra_footer
    }
    'Debian': {
      $debian_method = $ipv4_dhcp ? {
        true  => 'dhcp',
        false => 'static',
      }
      $os_header = "iface ${interface} inet ${debian_method}\n"
      $os_footer = ''
      $os_settings = {
        address => $ipv4_address,
        netmask => $ipv4_netmask,
      }
      $extra_settings = $debian_extra_settings
      $extra_header = $debian_extra_header
      $extra_footer = $debian_extra_footer
    }
    'SuSE': {
      $os_header = ''
      $os_footer = ''
      $os_settings = {
        'STARTMODE' => $enable ? {
          true  => 'auto',
          false => 'off',
        },
        'BOOTPROTO' => $ipv4_dhcp ? {
          true  => 'dhcp',
          false => 'static',
        },
        'DEVICE'    => $interface,
        'IPADDR'    => $ipv4_address,
        'NETWORK'   => $ipv4_network,
        'NETMASK'   => $ipv4_netmask,
        'BROADCAST' => $ipv4_broadcast,
        'GATEWAY'   => $ipv4_gateway,
        'MTU'       => $ipv4_mtu,
        'LLADDR'    => $mac,
      }
      $extra_settings = $suse_extra_settings
      $extra_header = $suse_extra_header
      $extra_footer = $suse_extra_footer
    }
    'Solaris': {
      $os_header = ''
      $os_footer = ''
      $os_settings = {}
      $extra_settings = $solaris_extra_settings
      $extra_header = $solaris_extra_header
      $extra_footer = $solaris_extra_footer
    }
    default: {}
  }


  # $settings variable is used in templates
  if $use_default_settings {
    $settings = delete_undef_values($os_settings + $extra_settings)
    $header = "${os_header}${extra_header}"
    $footer = "${os_footer}${extra_footer}"
  } else {
    $settings = delete_undef_values($extra_settings)
    $header = $extra_header
    $footer = $extra_footer
  }

  $params = {
    settings    => $settings,
    header      => $header,
    footer      => $footer,
    interface   => $interface,
    description => $description,
  }

  # Content used in interface configuration file
  $template_type=$template[-4,4]
  case $template_type {
    '.epp': {
      $content = epp($template, { params => $params } )
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
    default: {}
  }

  # Define how to restart network service
  $real_config_file_notify = $config_file_notify ? {
    'class_default' => $::network::manage_config_file_notify,
    default         => $config_file_notify,
  }


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
        notify  => $real_config_file_notify,
      }
    }

    # On Suse family we manage "/etc/sysconfig/network/ifcfg-${title}"
    'SLES', 'OpenSuSE': {
      # Prerequisites
      if $manage_prerequisites
      and is_hash($extra_params) {
        if has_key($extra_params,'VLAN_ID')
        and !defined(Package['vlan']) {
          package { 'vlan':
            ensure => 'present',
          }
          Package['vlan'] -> File[$config_file_path]
        }
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
        notify  => $real_config_file_notify,
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
      if $use_netplan {
        if $ipv4_address {
          if $ipv4_netmask {
            # TODO Handle ipv6 and multiple addresses
            $ipv4_cidr = netmask2cidr($ipv4_netmask)
            $addressv4 = [ "${ipv4_address}/${ipv4_cidr}" ]
          } else {
            fail('A ipv4_netmask must be set if ipv4_address is present')
          }
        } else {
          $addressv4 = undef
        }
        network::netplan::interface { $interface:
          dhcp4     => $ipv4_dhcp,
          dhcp6     => $ipv6_dhcp,
          addresses => $addressv4,
          gateway4  => $ipv4_gateway,
          gateway6  => $ipv6_gateway,
        }
      } else {
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
            notify  => $real_config_file_notify,
          }
          if ! defined(File_line['config_file_per_interface']) {
            file_line { 'config_file_per_interface':
              ensure => $ensure,
              path   => '/etc/network/interfaces',
              line   => 'source /etc/network/interfaces.d/*.cfg',
              notify => $real_config_file_notify,
            }
          }
        } else {
          # Scenario with everything configured in /etc/network/interfaces
          if ! defined(Concat['/etc/network/interfaces']) {
            concat { '/etc/network/interfaces':
              mode   => '0644',
              owner  => 'root',
              group  => 'root',
              notify => $real_config_file_notify,
            }
          }
          concat::fragment { "interface-${title}":
            target  => '/etc/network/interfaces',
            content => $content,
            #         order   => pick($options['order'], 50),
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
    }

    # On Cumulus we manage "/etc/network/interfaces.d/${name}"
    # and line addon_scripts_support=1 in /etc/network/ifupdown2/ifupdown2.conf
    'CumulusLinux': {
      # Configuration
      file { $config_file_path:
        ensure  => $ensure,
        content => $content,
        notify  => $real_config_file_notify,
      }
      if ! defined(File_line['config_file_per_interface']) {
        file_line { 'config_file_per_interface':
          ensure => $ensure,
          path   => '/etc/network/ifupdown2/ifupdown2.conf',
          line   => 'addon_scripts_support=1',
          match  => 'addon_scripts_suppor*',
          notify => $real_config_file_notify,
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
          ensure => running,
          enable => true,
        }
      }
      Service['svc:/network/physical:default'] ~> File[$config_file_path]
      Service['svc:/network/physical:default'] ~> Exec["create ipaddr ${interface}"]
    }

    # Other OS not supported
    default: {
      if ! $suppress_warnings {
        alert("${::operatingsystem} not supported. Nothing done here. Set \$suppress_warnings to true to disable this message")
      }
    }
  }

}
