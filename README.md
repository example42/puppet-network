# network

[![Build Status](https://travis-ci.org/example42/puppet-network.png?branch=master)](https://travis-ci.org/example42/puppet-network)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup](#setup)
    * [Resources managed by network module](#resources-managed-by-network-module)
    * [Setup requirements](#setup-requirements)
    * [Beginning with module network](#beginning-with-module-network)
4. [Usage](#usage)
5. [Hiera examples](#hiera-examples)
6. [Operating Systems Support](#operating-systems-support)
7. [Development](#development)

## Overview

This module configures networking on Linux and Solaris. It manages network parameters, interfaces, routes,
rules and routing tables.

## Module Description

Main class is used as entrypoint for general variables.
 
It manages hostname configuration and has hiera hash lookups to generate the following, provided, resources:

- network::interface - Define to manage network interfaces
- network::route - Define to manage network routes
- network::mroute - Define to manage network routes - Alternative with easier management of multiple routes per interface
- network::routing_table - Define to manage iproute2 routing tables
- network::rule - Define to manage network rules

## Setup

### Setup Requirements
* PuppetLabs [stdlib module](https://github.com/puppetlabs/puppetlabs-stdlib)
* PuppetLabs [concat module](https://github.com/puppetlabs/puppetlabs-concat)
* Puppet version >= 3.0.0 < 7.0.0
* Facter version >= 1.6.2

### Beginning with module network

The main class arguments can be provided either via Hiera (from Puppet 3.x) or direct parameters:

        class { 'network':
          parameter => value,
        }


The module provides a generic network::conf define to manage any file in the config_dir_path which is:

  On 'Debian' osfamily: '/etc/network',

  On 'Redhat' osfamily: '/etc/sysconfig/network-scripts',

  On 'Suse' osfamily: '/etc/sysconfig/network',

        network::conf { 'if-up.d/my_script':
          template => 'site/network/my_script',
        }

The module provides a cross OS compliant define to manage single interfaces: network::interface

IMPORTANT NOTICE: On Debian if you use network::interface once you must provide ALL the network::interface defines for all your interfaces. It requires separate declarations for each IP stack on each interface.
Please keep in mind Debian and RedHat do not share the same approach in IPv4 / IPv6 management and thus require different hash structures.

To configure a dhcp interface

        network::interface { 'eth0':
          enable_dhcp => true,
        }

To configure a static interface with basic parameters

        network::interface { 'eth1':
          ipaddress => '10.42.42.50',
          netmask   => '255.255.255.0',
        }


## Generic interface parameters configation examples

You have different possible approaches in the usage of this module. Use the one you prefer.

* Just use the network::interface defines:

        network::interface { 'eth0':
          enable_dhcp => true,
        }

        network::interface { 'eth1':
          ipaddress => '10.42.42.50',
          netmask   => '255.255.255.0',
        }

* Use the main network class and the interfaces_hash to configure all the interfaces 

        class { 'network':
          interfaces_hash => {
            'eth0' => {
              enable_dhcp => true,
            },
            'eth1' => {
              ipaddress => '10.42.42.50',
              netmask   => '255.255.255.0',
            },
          },
        }

Same information as Hiera data in yaml format:

        network::interfaces_hash:
          eth0:
            enable_dhcp: true
          eth1:
            ipaddress: '10.42.42.50'
            netmask: '255.255.255.0'

* Use the main network class and the usual stdmod parameters to manage the (main) network configuration file

  On 'Debian' osfamily: '/etc/network/interfaces',

  On 'Redhat' osfamily: '/etc/sysconfig/network-scripts/ifcfg-eth0' # Yes, quite opinionated, you can change it with config_file_path.

  On 'Suse' osfamily: '/etc/sysconfig/network/ifcfg-eth0'

        class { 'network':
          config_file_template => 'site/network/network.conf.erb',
        }

* Manage the whole configuration directory

        class { 'network':
          config_dir_source  => 'puppet:///modules/site/network/conf/',
        }

* DO NOT automatically restart the network service after configuration changes (either via the main network class or via network::interfaces)

        class { 'network':
          config_file_notify => '',
        }


* The network::interface exposes, and uses in the default templates, network configuration parameters available on Debian (most), RedHat (some), Suse (most) so it's flexible, easily expandable and should adapt to any need, but you may still want to provide a custom template with:

        network::interface { 'eth0':
          enable_dhcp => true,
          template    => "site/network/interface/${::osfamily}.erb",
        }

## Network routes management examples

* The network::route can be used to define static routes on Debian and RedHat systems. The following example manages a static route on eth0

        network::route { 'eth0':
          ipaddress => [ '192.168.17.0', ],
          netmask   => [ '255.255.255.0', ],
          gateway   => [ '192.168.17.250', ],
        }

  On 'Debian' osfamily: it will create 2 files: '/etc/network/if-up.d/z90-route-eth0' and '/etc/network/if-down.d/z90-route-eth0',

  On 'RedHat' osfamily: it will create the file '/etc/sysconfig/network-scripts/route-eth0'

  You can provide to the main network class the routes_hash parameter to manage all your routes via a hash.

* This example add 2 static routes on the interface bond2

        network::route { 'bond2':
          ipaddress => [ '192.168.2.0', '10.0.0.0', ],
          netmask   => [ '255.255.255.0', '255.0.0.0', ],
          gateway   => [ '192.168.1.1', '10.0.0.1', ],
        }

* To configure the default route on Suse, use the routes_hash parameter, like in the following example:

        class { 'network':
          routes_hash => {
            'eth0' => {
              ipaddress   => [ 'default', ],
              gateway     => [ '192.168.0.1', ],
              netmask     => [ '-', ],
              interface   => 'eth0',
            }
          }
        }

* An alternative way to manage routes is using the network::mroute define, which expects a hash of one or more routes where you specify the network and the gateway (either as ip or device name):

        network::mroute { 'bond2':
          routes => {
            '192.168.2.0/24' => '192.168.1.1',
            '10.0.0.0/8'     => '10.0.0.1',
            '80.81.82.0/16'  => 'bond0',
          }
        }

* The network::routing_table and network::rule classes can be used to configure ip rules and routing tables. Make sure to define a routing table before using it, like in this example:

        network::routing_table { 'vlan22':
          table_id => '200',
        }

        network::rule { 'eth0':
          iprule => ['from 192.168.22.0/24 lookup vlan22', ],
        }

When using RHEL or similiar with NetworkManager the resource isn't supported as NetworkManager won't respect those files. Instead you can add the iprule to the interface resource. Also NetworkManager won't recognize name schemes for routing tables. Use the numeric value instead:

        network::interface { 'eth0':
          ipaddress => '10.42.42.50',
          netmask   => '255.255.255.0',
          iprule    => ['from 192.168.22.0/24 lookup 22', ],
        }

You can then add routes to this routing table:

       network::route { 'eth1':
         ipaddress => [ '192.168.22.0', ],
         netmask   => [ '255.255.255.0', ],
         gateway   => [ '192.168.22.1', ],
         table     => [ 'vlan22' ],
       }

If adding routes to a routing table on an interface with multiple routes, it
is necessary to specify false or 'main' for the table on the other routes.
The 'main' routing table is where routes are added by default. E.g. this:

       network::route { 'bond0':
         ipaddress => [ '192.168.2.0', '10.0.0.0', ]
         netmask   => [ '255.255.255.0', '255.0.0.0', ],
         gateway   => [ '192.168.1.1', '10.0.0.1', ],
       }

       network::route { 'bond0':
         ipaddress => [ '192.168.3.0', ],
         netmask   => [ '255.255.255.0', ],
         gateway   => [ '192.168.3.1', ],
         table     => [ 'vlan22' ],
       }

would need to become:

       network::route { 'bond0':
         ipaddress => [ '192.168.2.0', '10.0.0.0', '192.168.3.0', ]
         netmask   => [ '255.255.255.0', '255.0.0.0', '255.255.255.0', ],
         gateway   => [ '192.168.1.1', '10.0.0.1', '192.168.3.1', ],
         table     => [ false, false, 'vlan22' ],
       }

The same applies if adding scope, source or gateway, i.e. false needs to be
specified for those routes without values for those parameters, if defining
multiple routes for the same interface.

The following definition:

       network::route { 'bond2':
         ipaddress => [ '0.0.0.0', '192.168.3.0' ]
         netmask   => [ '0.0.0.0', '255.255.255.0' ],
         gateway   => [ '192.168.3.1', false ],
         scope     => [ false, 'link', ],
         source    => [ false, '192.168.3.10', ],
         table     => [ 'vlan22' 'vlan22', ],
       }

yields the following routes in table vlan22:

       # ip route show table vlan22
       default via 192.168.3.1 dev bond2
       192.168.3.0/255.255.255.0 dev bond2 scope link src 192.168.3.10

Normally the link level routing (192.168.3.0/255.255.255.0) is added
automatically by the kernel when an interface is brought up. When using routing
rules and routing tables, this does not happen, so this route must be added
manually.


## Hiera examples

Here are some examples of usage via Hiera (with yaml backend).

Main class settings:

    network::hostname: 'web01'
    network::gateway: 192.168.0.1 # Default gateway (on RHEL systems)
    network::hiera_merge: true # Use hiera_hash() instead of hiera() to resolve the values for the following hashes

Configuration of interfaces (check ```network::interface``` for all the available params.

Single interface via dhcp:

    network::interfaces_hash:
      eth0:
        enable_dhcp: true

Bond interface:

    eth0:
      method: manual
      bond_master: 'bond3'
      allow_hotplug: 'eth0'
      manage_order: '08'
    eth1:
      method: manual
      bond_master: 'bond3'
      allow_hotplug: 'eth1'
      manage_order: '08'
    bond3:
      ipaddress: "10.0.28.10"
      netmask: '255.255.248.0'
      gateway: "10.0.24.1"
      dns_nameservers: "8.8.8.8 8.8.4.4"
      dns_search: 'my.domain'
      bond_mode: 'balance-alb'
      bond_miimon: '100'
      bond_slaves: []

Debian/Ubuntu IPv4/IPv6 management example for basic IP config, IP aliaseconfig and VLAN config :

    'eth0:0v4':
       'enable':          'true'
       'bootproto':       'none'
       'peerdns':         'no'
       'userctl':         'no'
       'restart_all_nic': 'false'
       'accept_ra':       '1'
       'type':            'Ethernet'
       'mtu':             '1500'
       'interface':       'eth0:0'
       'ipaddress':       'X.X.X.X/22'
       'family':          'inet'

    'eth0:0v6':
       'enable':          'true'
       'bootproto':       'none'
       'peerdns':         'no'
       'userctl':         'no'
       'restart_all_nic': 'false'
       'accept_ra':       '1'
       'autoconf':        '0'
       'type':            'Ethernet'
       'mtu':             '1500'
       'interface':       'eth0:0'
       'ipaddress':       'X.X.X.1::85/64'
       'family':          'inet6'
    
    'eth1v4':
       'enable':          'true'
       'bootproto':       'none'
       'peerdns':         'no'
       'userctl':         'no'
       'restart_all_nic': 'false'
       'accept_ra':       '0'
       'type':            'Ethernet'
       'mtu':             '1500'
       'interface':       'eth1'
       'ipaddress':       'X.X.X.1/29'
       'family':          'inet'
    
    'eth1v6':
       'enable':          'true'
       'bootproto':       'none'
       'peerdns':         'no'
       'userctl':         'no'
       'restart_all_nic': 'false'
       'accept_ra':       '0'
       'type':            'Ethernet'
       'mtu':             '1500'
       'interface':       'eth1'
       'ipaddress':       'X.X.X.1:bb:43::2/64'
       'family':          'inet6'
    
    'eth1.12v4':
       'enable':          'true'
       'bootproto':       'none'
       'peerdns':         'no'
       'userctl':         'no'
       'restart_all_nic': 'false'
       'accept_ra':       '1'
       'type':            'Ethernet'
       'mtu':             '1500'
       'vlan':            'yes'
       'interface':       'eth1.12'
       'ipaddress':       'X.X.X.1/29'
       'family':          'inet'
    
    'eth1.12v6':
       'enable':          'true'
       'bootproto':       'none'
       'peerdns':         'no'
       'userctl':         'no'
       'restart_all_nic': 'false'
       'accept_ra':       '1'
       'autoconf':        '0'
       'type':            'Ethernet'
       'mtu':             '1500'
       'vlan':            'yes'
       'interface':       'eth1.12'
       'ipaddress':       'X.X.X.1:dd:3::2/64'
       'family':          'inet6'
    
    'eth0v4':
       'enable':          'true'
       'bootproto':       'none'
       'peerdns':         'no'
       'userctl':         'no'
       'restart_all_nic': 'false'
       'accept_ra':       '1'
       'type':            'Ethernet'
       'mtu':             '1500'
       'dns_nameservers': 'X.X.X.1 X.X.X.1 X.X.X.1'
       'interface':       'eth0'
       'ipaddress':       'X.X.X.X/22'
       'gateway':         'X.X.X.1'
       'family':          'inet'
    
    'eth0v6':
       'enable':          'true'
       'bootproto':       'none'
       'peerdns':         'no'
       'userctl':         'no'
       'restart_all_nic': 'false'
       'accept_ra':       '1'
       'autoconf':        '0'
       'type':            'Ethernet'
       'mtu':             '1500'
       'interface':       'eth0'
       'ipaddress':       'X.X.X.1::85/64'
       'gateway':         'X.X.X.1::1'
       'family':          'inet6'

Configuration of multiple static routes (using the ```network::route``` define, when more than one route is added the elements of the arrays have to be ordered coherently):

    network::routes_hash:
      eth0:
        ipaddress:
          - 99.99.228.0
          - 100.100.244.0
        netmask:
          - 255.255.255.0
          - 255.255.252.0
        gateway:
          - 192.168.0.1
          - 174.136.107.1


Configuration of multiple static routes (using the newer ```network::mroute``` define) you can specify as gateway either a device or an IP or also add a table reference:

    network::mroutes_hash:
      eth0:
        routes:
          99.99.228.0/24: eth0
          100.100.244.0/22: 174.136.107.1
          101.99.228.0/24: 'eth0 table 1'


## Operating Systems Support

This is tested on these OS:

- RedHat / CentOS / OracleLinux
  - 5
  - 6
  - 7
  - 8
- Debian
  - 6
  - 7
  - 8
- Ubuntu
  - 10.04
  - 12.04
  - 14.04
  - partly verified on Ubuntu 16.04
- Suse (ifrule files are only supported on Suse with wicked >= 0.6.33)
  - OpenSuse 12
  - SLES 11SP3
  - SLES 12SP1
  - SLES 15


## Development

Pull requests (PR) and bug reports via GitHub are welcomed.

When submitting PR please follow these quidelines:
- Provide puppet-lint compliant code
- If possible provide rspec tests
- Follow the module style and stdmod naming standards

When submitting bug report please include or link:
- The Puppet code that triggers the error
- The output of facter on the system where you try it
- All the relevant error logs
- Any other information useful to understand the context
