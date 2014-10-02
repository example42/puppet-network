#
# = Define: network::interface
#
# This define manages interfaces.
# Currently only Debian and RedHat families supported.
# Some parameters are supported only for specific families
#
# == Common parameters
#
# $enable_dhcp
#   Boolean. Default: false
#   Activates DHCP on the interface
#
# [*ipaddress*]
# [*netmask*]
# [*broadcast*]
# [*macaddress*]
#   String. Default: undef
#   Standard network parameters
#
# [*enable*]
#   Boolean. Default: true
#   Manages the interface presence. Possible values:
#   * true   - Interface created and enabled at boot.
#   * false  - Interface removed from boot.
#
# [*template*]
#   String. Optional. Default: Managed by module.
#   Provide an alternative custom template to use for configuration of:
#   - On Debian: file fragments in /etc/network/interfaces
#   - On RedHat: files /etc/sysconfig/network-scripts/ifcfg-${name}
#   You can copy and adapt network/templates/interface/${::osfamily}.erb
#
#
# == Debian only parameters
#
#  $address       = undef,
#    Both ipaddress (standard name) and address (Debian param name) if set
#    configure the ipv4 address of the interface. If both are present address is used.
#
#  $manage_order  = 10,
#    This is used by concat to define the order of your fragments, can be used to load
#    an interface before another.
#    default it's 10.
#
#  $method        = '',
#    Both enable_dhcp (standard) and method (Debian specific param name) if set
#    configure dhcp on the interface via the method setting.
#    If both are present method is used.
#
#  $up            = [ ],
#  $pre_up        = [ ],
#  $post_up        = [ ],
#  $down          = [ ],
#  $pre_down      = [ ],
#  $post_down      = [ ],
#    Map to Debian interfaces parameters (with _ instead of -)
#    Note that these params MUST be arrays, even if with only one element
#
# Check the arguments in the code for the other Debian specific settings
# If defined they are set in the used template.
#
# == RedHat only parameters
#
#  $ipaddr        = undef,
#    Both ipaddress (standard name) and ipaddr (RedHat param name) if set
#    configure the ipv4 address of the interface. If both are present ipaddr is used.
#
#  $hwaddr        = undef,
#    Both macaddress (standard name) and hwaddr (RedHat param name) if set
#    configure the mac address of the interface. If both are present hwaddr is used.
#
#  $bootproto        = '',
#    Both enable_dhcp (standard) and bootproto (Debian specific param name) if set
#    configure dhcp on the interface via the bootproto setting.
#    If both are present bootproto is used.
#
# Check the arguments in the code for the other RedHat specific settings
# If defined they are set in the used template.
#
define network::interface (

  $enable          = true,
  $ensure          = 'present',
  $template        = "network/interface/${::osfamily}.erb",
  $interface       = $name,

  $enable_dhcp     = false,

  $ipaddress       = '',
  $netmask         = undef,
  $network         = undef,
  $broadcast       = undef,
  $gateway         = undef,
  $hwaddr          = undef,
  $mtu             = undef,


  ## Debian specific
  $manage_order    = '10',
  $auto            = true,
  $allow_hotplug   = undef,
  $method          = '',
  $family          = 'inet',
  $stanza          = 'iface',
  $address         = '',
  $dns_search      = undef,
  $dns_nameservers = undef,
  # For method: static
  $metric          = undef,
  $pointopoint     = undef,

  # For method: dhcp
  $hostname        = undef,
  $leasehours      = undef,
  $leasetime       = undef,
  $client          = undef,

  # For method: bootp
  $bootfile        = undef,
  $server          = undef,

  # For method: tunnel
  $mode            = undef,
  $endpoint        = undef,
  $dstaddr         = undef,
  $local           = undef,
  $ttl             = undef,

  # For method: ppp
  $provider        = undef,
  $unit            = undef,
  $options         = undef,

  # For inet6 family
  $privext         = undef,
  $dhcp            = undef,
  $media           = undef,
  $accept_ra       = undef,
  $autoconf        = undef,
  $vlan_raw_device = undef,

  # Common ifupdown scripts
  $up              = [ ],
  $pre_up          = [ ],
  $post_up         = [ ],
  $down            = [ ],
  $pre_down        = [ ],
  $post_down       = [ ],

  # For bonding
  $slaves          = [ ],
  $bond_mode       = undef,
  $bond_miimon     = undef,
  $bond_downdelay  = undef,
  $bond_updelay    = undef,
  $bond_master     = undef,
  $bond_primary    = undef,
  $bond_slaves     = undef,
  $bond_xmit_hash_policy    = undef,

  # For bridging
  $bridge_ports    = undef,
  $bridge_stp      = undef,
  $bridge_fd       = undef,
  $bridge_maxwait  = undef,

  # RedHat specific
  $ipaddr          = '',
  $uuid            = undef,
  $bootproto       = '',
  $userctl         = 'no',
  $type            = 'Ethernet',
  $ethtool_opts    = undef,
  $ipv6init        = undef,
  $dhcp_hostname   = undef,
  $srcaddr         = undef,
  $peerdns         = '',
  $onboot          = '',
  $dns1            = undef,
  $dns2            = undef,
  $master          = undef,
  $slave           = undef,
  $bonding_opts    = undef,
  $vlan            = undef,
  $bridge          = undef,

  # Suse specific
  $startmode       = '',
  $usercontrol     = 'no'

  ) {

  validate_bool($auto)
  validate_bool($enable)

  validate_array($up)
  validate_array($pre_up)
  validate_array($down)
  validate_array($pre_down)

  $manage_hwaddr = $hwaddr ? {
    default => $hwaddr,
  }

  $manage_method = $method ? {
    ''     => $enable_dhcp ? {
      true  => 'dhcp',
      false => 'static',
    },
    default => $method,
  }

  # Debian specific
  case $manage_method {
    'dhcp': { $manage_address = undef }
    'none': { $manage_address = undef }
    default: {
        $manage_address = $address ? {
          ''      => $ipaddress,
          default => $address,
        }
      }
  }

  # Redhat and Suse specific
  $manage_bootproto = $bootproto ? {
    ''     => $enable_dhcp ? {
      true  => 'dhcp',
      false => 'none',
    },
    default => $bootproto,
  }
  $manage_peerdns = $peerdns ? {
    ''     => $manage_bootproto ? {
      'dhcp'  => 'yes',
      default => 'no',
    },
    default => $peerdns,
  }
  $manage_ipaddr = $ipaddr ? {
    ''      => $ipaddress,
    default => $ipaddr,
  }
  $manage_onboot = $onboot ? {
    ''     => $enable ? {
      true   => 'yes',
      false  => 'no',
    },
    default => $onboot,
  }
  $manage_startmode = $startmode ? {
    ''     => $enable ? {
      true   => 'auto',
      false  => 'off',
    },
    default => $startmode,
  }

  # Resources

  case $::osfamily {

    'Debian': {
      if ! defined(Concat['/etc/network/interfaces']) {
        concat { '/etc/network/interfaces':
          mode   => '0644',
          owner  => 'root',
          group  => 'root',
          notify => $network::manage_config_file_notify,
        }
      }

      if ! defined(Network::Interface['lo']) {
        network::interface { 'lo':
          address      => '127.0.0.1',
          method       => 'loopback',
          manage_order => '05',
        }
      }

      concat::fragment { "interface-${name}":
        target  => '/etc/network/interfaces',
        content => template($template),
        order   => $manage_order,
      }
    }

    'RedHat': {
      file { "/etc/sysconfig/network-scripts/ifcfg-${name}":
        ensure  => $ensure,
        content => template($template),
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        notify  => $network::manage_config_file_notify,
      }
    }

    'Suse': {
      file { "/etc/sysconfig/network/ifcfg-${name}":
        ensure  => $ensure,
        content => template($template),
        mode    => '0600',
        owner   => 'root',
        group   => 'root',
        notify  => $network::manage_config_file_notify,
      }
    }

    default: {
      alert("${::operatingsystem} not supported. Review params.pp for extending support. No changes done here.")
    }

  }

}
