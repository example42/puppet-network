#
# = Define: network::interface
#
# This define manages interfaces.
# Currently only Debian and RedHat families supported.
# Some parameters are supported only for specific families
#
# == Common parameters
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
#  $up            = [ ],
#  $pre_up        = [ ],
#  $down          = [ ],
#  $pre_down      = [ ],
#    Map to Debian interfaces parameters (with _ instead of -)
#    Note that these params MUST be arrays, even if with only one element
#
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
#  $uuid          = undef,
#  $bootproto     = 'none',
#  $userctl       = 'no',
#  $type          = 'Ethernet',
#  $ethtool_opts  = undef,
#  $ipv6init      = undef,
#  $dhcp_hostname = undef,
#  $srcaddr       = undef,
#  $peerdns       = '',
#  $dns1          = undef,
#  $dns2          = undef,
#  $master        = undef,
#  $slave         = undef,
#  $bonding_opts  = undef,
#    Map to RedHat ifcfg files parameters.
#
#
define network::interface (

  $enable        = true,
  $template      = "network/interface/${::osfamily}.erb",

  $ipaddress     = undef,
  $netmask       = undef,
  $network       = undef,
  $broadcast     = undef,
  $gateway       = undef,
  $hwaddr        = undef,
  $mtu           = undef,


  ## Debian specific
  $auto          = true,
  $method        = 'static',
  $family        = 'inet',
  $stanza        = 'iface',
  $address       = undef,

  # For method: static
  $metric        = undef,
  $pointopoint   = undef,

  # For method: dhcp
  $hostname      = undef,
  $leasehours    = undef,
  $leasetime     = undef,
  $client        = undef,

  # For method: bootp
  $bootfile      = undef,
  $server        = undef,

  # For method: tunnel
  $mode          = undef,
  $endpoint      = undef,
  $dstaddr       = undef,
  $local         = undef,
  $ttl           = undef,

  # For method: ppp
  $provider      = undef,
  $unit          = undef,
  $options       = undef,

  # For inet6 family
  $privext       = undef,
  $dhcp          = undef,
  $media         = undef,
  $accept_ra     = undef,
  $autoconf      = undef,

  # Common ifupdown scripts
  $up            = [ ],
  $pre_up        = [ ],
  $post_up       = [ ],
  $down          = [ ],
  $pre_down      = [ ],
  $post_down     = [ ],


  # RedHat specific
  $ipaddr        = undef,
  $uuid          = undef,
  $bootproto     = 'none',
  $userctl       = 'no',
  $type          = 'Ethernet',
  $ethtool_opts  = undef,
  $ipv6init      = undef,
  $dhcp_hostname = undef,
  $srcaddr       = undef,
  $peerdns       = '',
  $dns1          = undef,
  $dns2          = undef,
  $master        = undef,
  $slave         = undef,
  $bonding_opts  = undef,


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

  # Debian specific
  $manage_address = $address ? {
    ''      => $ipaddress,
    default => $address,
  }


  # Redhat specific
  $manage_peerdns = $peerdns ? {
    ''     => $bootproto ? {
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


  # Resources

  case $::osfamily {

    'Debian': {
      if ! defined(Concat['/etc/network/interfaces']) {
        concat { '/etc/network/interfaces':
          mode    => '0644',
          owner   => 'root',
          group   => 'root',
        }
      }

      concat::fragment { "interface-${name}":
        target  => '/etc/network/interfaces',
        content => template($template),
        notify  => $network::manage_config_file_notify,
      }
    }

    'RedHat': {
      file { "/etc/sysconfig/network-scripts/ifcfg-${name}":
        ensure  => present,
        content => template($template),
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        notify  => $network::manage_config_file_notify,
      }
    }

  }


}

