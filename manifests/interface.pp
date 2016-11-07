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
# [*hwaddr*]
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
# [*options*]
#   A generic hash of custom options that can be used in a custom template
#
# == Debian only parameters
#
#  $address       = undef,
#    Both ipaddress (standard name) and address (Debian param name) if set
#    configure the ipv4 address of the interface.
#    If both are present address is used.
#
#  $manage_order  = 10,
#    This is used by concat to define the order of your fragments,
#    can be used to load an interface before another.
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
#  $type          = 'Ethernet',
#    Defaults to 'Ethernet', but following types are supported for OVS:
#    "OVSPort", "OVSIntPort", "OVSBond", "OVSTunnel" and "OVSPatchPort".
#
#  $ipaddr        = undef,
#    Both ipaddress (standard name) and ipaddr (RedHat param name) if set
#    configure the ipv4 address of the interface.
#    If both are present ipaddr is used.
#
#  $hwaddr        = undef,
#    hwaddr if set configures the mac address of the interface.
#
#  $bootproto        = '',
#    Both enable_dhcp (standard) and bootproto (Debian specific param name),
#    if set, configure dhcp on the interface via the bootproto setting.
#    If both are present bootproto is used.
#
#  $arpcheck      = undef
#    Whether the interface will check if the supplied IP address is already in
#    use. Valid values are undef, "yes", "no".
#
#  $arp           = undef
#    Used to enable or disable ARP completely for an interface at initialization
#    Valid values are undef, "yes", "no".
#
#  $nozeroconf    = undef
#    Used to enable or disable ZEROCONF routes completely for an
#    interface at initialization
#    Valid values are undef, "yes, 'no".
#
#  $linkdelay     = undef
#    Used to introduce a delay (sleep) of the specified number of seconds when
#    bringing an interface up.
#
#  $check_link_down = false
#    Set to true to add check_link_down function in the interface file
#
#  $hotswap = undef
#    Set to no to prevent interface from being activated when hot swapped - Default is yes
#
# == RedHat only Open vSwitch specific parameters
#
#  $devicetype      = undef,
#    Always set to "ovs" if configuring OVS* type.
#
#  $bond_ifaces     = undef,
#    Physical interfaces for "OVSBond".
#
#  $ovs_bridge      = undef,
#    For types other than "OVSBridge" type. It specifies the OVS bridge
#    to which port, patch or tunnel should be attached to.
#
#  $ovs_extra       = undef,
#    Optional: extra ovs-vsctl commands seperate by "--" (double dash)
#
#  $ovs_options     = undef,
#    Optional: extra options to set in the Port table.
#    Check ovs-vsctl's add-port man page.
#
#  $ovs_patch_peer  = undef,
#    Patche's peer on the other bridge for "OVSPatchPort" type.
#
#  $ovs_tunnel_type = undef,
#    Tunnel types (eg. "vxlan", "gre") for "OVSTunnel" type.
#
#  $ovs_tunnel_options = undef,
#    Tunnel options (eg. "remote_ip") for "OVSTunnel" type.
#
# Check the arguments in the code for the other RedHat specific settings
# If defined they are set in the used template.
#
# == Suse only parameters
#
# Check the arguments in the code for the other Suse specific settings
# If defined they are set in the used template.
#
#
# == Red Hat zLinux on IBM ZVM/System Z (s390/s390x) only parameters
#
#  $subchannels = undef,
#     The hardware addresses of QETH or Hipersocket hardware.
#
#  $nettype = undef,
#     The networking hardware type.  qeth, lcs or ctc.
#     The default is 'qeth'.
#
define network::interface (

  $enable          = true,
  $ensure          = 'present',
  $template        = "network/interface/${::osfamily}.erb",
  $options         = undef,
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
  $bond_lacp_rate  = undef,
  $bond_master     = undef,
  $bond_primary    = undef,
  $bond_slaves     = [ ],
  $bond_xmit_hash_policy    = undef,
  $bond_num_grat_arp = undef,
  $bond_arp_all = undef,
  $bond_arp_interval = undef,
  $bond_arp_iptarget = undef,
  $bond_fail_over_mac = undef,
  $use_carrier     = undef,
  $primary_reselect = undef,

  # For teaming
  $team_config = undef,
  $team_master = undef,

  # For bridging
  $bridge_ports    = [ ],
  $bridge_stp      = undef,
  $bridge_fd       = undef,
  $bridge_maxwait  = undef,
  $bridge_waitport = undef,

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
  $peerntp         = '',
  $onboot          = '',
  $defroute        = undef,
  $dns1            = undef,
  $dns2            = undef,
  $domain          = undef,
  $nm_controlled   = undef,
  $master          = undef,
  $slave           = undef,
  $bonding_master  = undef,
  $bonding_opts    = undef,
  $vlan            = undef,
  $vlan_name_type  = undef,
  $physdev         = undef,
  $bridge          = undef,
  $arpcheck        = undef,
  $zone            = undef,
  $arp             = undef,
  $nozeroconf      = undef,
  $linkdelay       = undef,
  $check_link_down = false,
  $hotplug         = undef,

  # RedHat specific for Open vSwitch
  $devicetype      = undef,
  $bond_ifaces     = undef,
  $ovs_bridge      = undef,
  $ovs_extra       = undef,
  $ovs_options     = undef,
  $ovs_patch_peer  = undef,
  $ovsrequries     = undef,
  $ovs_tunnel_type = undef,
  $ovs_tunnel_options = undef,
  $ovsdhcpinterfaces  = undef,

  # RedHat specifice for zLinux
  $subchannels     = undef,
  $nettype         = undef,
  $layer2          = undef,

  ## Suse specific
  $startmode       = '',
  $usercontrol     = 'no',
  $firewall        = undef,
  $aliases         = undef,
  $remote_ipaddr   = undef,

  # For bonding
  $bond_moduleopts = undef,
  # also used for Suse bonding: $bond_master, $bond_slaves

  # For bridging
  $bridge_fwddelay = undef,
  # also used for Suse bridging: $bridge, $bridge_ports, $bridge_stp

  # For vlan
  $etherdevice     = undef,
  # also used for Suse vlan: $vlan

  ) {

  include ::network

  validate_bool($auto)
  validate_bool($enable)

  validate_array($up)
  validate_array($pre_up)
  validate_array($down)
  validate_array($pre_down)
  validate_array($slaves)
  validate_array($bond_slaves)
  validate_array($bridge_ports)

  # $subchannels is only valid for zLinux/SystemZ/s390x.
  if $::architecture == 's390x' {
    validate_array($subchannels)
    validate_re($nettype, '^(qeth|lcs|ctc)$', "${name}::\$nettype may be 'qeth', 'lcs' or 'ctc' only and is set to <${nettype}>.")
    validate_re($layer2, '^0|1$', "${name}::\$layer2 must be 1 or 0 and is to <${layer2}>.")
  }

  if $arp != undef and ! ($arp in ['yes', 'no']) {
    fail('arp must be one of: undef, yes, no')
  }

  if $arpcheck != undef and ! ($arpcheck in ['yes', 'no']) {
    fail('arpcheck must be one of: undef, yes, no')
  }

  if $nozeroconf != undef and ! ($nozeroconf in ['yes', 'no']) {
    fail('nozeroconf must be one of: undef, yes, no')
  }

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
    'auto': { $manage_address = undef }
    'bootp': { $manage_address = undef }
    'dhcp': { $manage_address = undef }
    'ipv4ll': { $manage_address = undef }
    'loopback': { $manage_address = undef }
    'manual': { $manage_address = undef }
    'none': { $manage_address = undef }
    'ppp': { $manage_address = undef }
    'wvdial': { $manage_address = undef }
    default: {
        $manage_address = $address ? {
          ''      => $ipaddress,
          default => $address,
        }
      }
  }

  # Redhat and Suse specific
  if $::operatingsystem == 'SLES' and $::operatingsystemrelease =~ /^12/ {
    $bootproto_false = 'static'
  } else {
    $bootproto_false = 'none'
  }

  $manage_bootproto = $bootproto ? {
    ''     => $enable_dhcp ? {
      true  => 'dhcp',
      false => $bootproto_false
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
  $manage_peerntp = $peerntp ? {
    ''     => $manage_bootproto ? {
      'dhcp'  => 'yes',
      default => 'no',
    },
    default => $peerntp,
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
  $manage_defroute = $defroute ? {
    true    => 'yes',
    false   => 'no',
    default => $defroute,
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
      if $vlan_raw_device {
        if !defined(Package['vlan']) {
          package { 'vlan':
            ensure => 'present',
          }
        }
      }

      if $network::config_file_per_interface {
        file { "interface-${name}":
          path    => "/etc/network/interfaces.d/${name}.cfg",
          content => template($template),
          notify  => $network::manage_config_file_notify
        }
        if ! defined(File_line['config_file_per_interface']) {
          file_line { 'config_file_per_interface':
            path   => '/etc/network/interfaces',
            line   => 'source /etc/network/interfaces.d/*.cfg',
            notify => $network::manage_config_file_notify,
          }
        }
      } else {
        if ! defined(Concat['/etc/network/interfaces']) {
          concat { '/etc/network/interfaces':
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            notify => $network::manage_config_file_notify,
          }
        }

        concat::fragment { "interface-${name}":
          target  => '/etc/network/interfaces',
          content => template($template),
          order   => $manage_order,
        }

      }

      if ! defined(Network::Interface['lo']) {
        network::interface { 'lo':
          address      => '127.0.0.1',
          method       => 'loopback',
          manage_order => '05',
        }
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
      if $vlan {
        if !defined(Package['vlan']) {
          package { 'vlan':
            ensure => 'present',
          }
        }
        Package['vlan'] ->
        File["/etc/sysconfig/network/ifcfg-${name}"]
      }
      if $bridge {
        if !defined(Package['bridge-utils']) {
          package { 'bridge-utils':
            ensure => 'present',
          }
        }
        Package['bridge-utils'] ->
        File["/etc/sysconfig/network/ifcfg-${name}"]
      }

      file { "/etc/sysconfig/network/ifcfg-${name}":
        ensure  => $ensure,
        content => template($template),
        mode    => '0600',
        owner   => 'root',
        group   => 'root',
        notify  => $network::manage_config_file_notify,
      }
    }

    'Solaris': {
      if $::operatingsystemrelease == '5.11' {
        if ! defined(Service['svc:/network/physical:nwam']) {
          service { 'svc:/network/physical:nwam':
            ensure => stopped,
            enable => false,
            before => [
              Service['svc:/network/physical:default'],
              Exec["create ipaddr ${title}"],
              File["hostname iface ${title}"],
            ],
          }
        }
      }
      case $::operatingsystemmajrelease {
        '11','5': {
          if $enable_dhcp {
            $create_ip_command = "ipadm create-addr -T dhcp ${title}/dhcp"
            $show_ip_command = "ipadm show-addr ${title}/dhcp"
          } else {
            $create_ip_command = "ipadm create-addr -T static -a ${ipaddress}/${netmask} ${title}/v4static"
            $show_ip_command = "ipadm show-addr ${title}/v4static"
          }
        }
        default: {
          $create_ip_command = 'true'
          $show_ip_command = 'true'
        }
      }
      exec { "create ipaddr ${title}":
        command => $create_ip_command,
        unless  => $show_ip_command,
        path    => '/bin:/sbin:/usr/sbin:/usr/bin:/usr/gnu/bin',
        tag     => 'solaris',
      }
      file { "hostname iface ${title}":
        ensure  => file,
        path    => "/etc/hostname.${title}",
        content => inline_template("<%= @ipaddress %> netmask <%= @netmask %>\n"),
        require => Exec["create ipaddr ${title}"],
        tag     => 'solaris',
      }
      host { $::fqdn:
        ensure       => present,
        ip           => $ipaddress,
        host_aliases => [$::hostname],
        require      => File["hostname iface ${title}"],
      }
      if ! defined(Service['svc:/network/physical:default']) {
        service { 'svc:/network/physical:default':
          ensure    => running,
          enable    => true,
          subscribe => [
            File["hostname iface ${title}"],
            Exec["create ipaddr ${title}"],
          ],
        }
      }
    }

    default: {
      alert("${::operatingsystem} not supported. No changes done here.")
    }

  }

}
