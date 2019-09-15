
# example42 puppet-network module

Example 42 Puppet module to manage networking on Linux and Solaris.

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with network](#setup)
    * [What network affects](#what-network-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with network](#beginning-with-network)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Backwards compatibility](#backwards-compatibility)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [Development - Guide for contributing to the module](#development)

## Description

This module configures networking on Linux and Solaris.

It manages hostname, interfaces, routes, rules and routing tables.

The new version (4) works only on Puppet 4 and later and has several changes in class and defines parameters.

Options to provide [backwards compatibility](#backwards-compatibility) are available in order to use the legacy versions of the module's defines.

## Module Description

Main class is used as entrypoint for general variables and wrapper for Hiera driven management of the provided defines.

Classes:

- network::hostname - Manages the system hostname

Defines:

- network::interface - Manages network interfaces
- network::route - Manages network routes
- network::routing_table - Manages iproute2 routing tables
- network::rule - Manages network rules
- network::netplan - Generic netplan.io configuration
- network::netplan::interface - Netplan.io interface configuration

Legacy defines (inherited from version 3 of the module):

- network::legacy::interface - Manages network interfaces
- network::legacy::route - Manages network routes
- network::legacy::mroute - Manages network routes in an alternative, easier to handle, way
- network::legacy::routing_table - Manages iproute2 routing tables
- network::legacy::rule - Manages network rules

## Setup

### What puppet-network affects

The main network class does nothing with default values for parameters but can be included and used
as entrypoints to manage via Hiera hashes of the defines provided in the modules.

Single defines manage the relevant network entity (interfaces, routes, rules, tables ...)

### Setup Requirements

Puppetlabs-stdlib module is the only prerequisite module.

Puppet 4 or later is required for this module.

If you have earlier Puppet versions use code from the 3.x tags.

### Beginning with network

Include the main class to be able to manage via Hiera the network resources handled by the module:

    include network
    
This allows to configure network resources with Hiera data like:

    network::hostname: server.example.com
    network::interfaces_hash:
      eth0:
        enable_dhcp: true
      eth1:
        ipaddress: '10.42.42.50'
        netmask: '255.255.255.0'
    network::routes_hash:
      eth1:
        routes:
          99.99.228.0/24: eth0
          100.100.244.0/22: 174.136.107.1
          101.99.228.0/24: 'eth0 table 1'
            
## Usage


## Reference

For full reference look at the defines documentation.

For configuration examples via Hiera look at the examples directory.

## Backwards compatibility

If you are using the version 3 of this module and are configuring networking via Hiera data, you must set the relevant
legacy options so that hashes of interface, route, and other resources can be maintained ad the legacy defines used.
You have to set this for each network resource type. By default the new versions are used.
On hiera configure something like (Yaml format):

    network::interfaces_legacy: true 
    network::rules_legacy: true 
    network::tables_legacy: true 
    network::routes_legacy: true 

Given the quite critical nature of the resources manages we highly recommend to test carefully the effect of an upgrade of
this module on your current infrastructure and to keep the first runs on noop mode.

Some configuration files might change as well, in minor details like new lines or spaces, even when using the legacy 
options. To avoid automatic restart of network service on a configuration change set:

    network::config_file_notify: false

## Limitations

This module works currently supports only the major Linux distributions (RedHat and derivatives, Debian and derivatives, included Cumulus, SuSE
and derivatives, Solaris).

The legacy defines are introduced for backwards compatibility only and are not supposed to be improved in the future.
The new, default, defines, are designed in a way to be more easily adaptable to custom needs (for example there's no need to add parameters
for any new or uncommon configuration entry).

## Development

To contribute to the module submit a Pull Request on GitHub.

Please be sure to provide:

- Code changes for syntax and lint
- Relevant documentation
- Relevant spec tests


