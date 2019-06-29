
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

- network::hostname - Manages hostname

Defines:

- network::interface - Manages network interfaces
- network::route - Manages network routes
- network::routing_table - Manages iproute2 routing tables
- network::rule - Manages network rules

Legacy defines (inherited from version 3 of the module):

- network::legacy::interface - Manages network interfaces
- network::legacy::route - Manages network routes
- network::legacy::mroute - Manages network routes in an alternative, easier to handle, way
- network::legacy::routing_table - Manages iproute2 routing tables
- network::legacy::rule - Manages network rules

## Setup

### What puppet-network affects


### Setup Requirements

Puppetlabs-stdlib module is the only prerequisite module.

Puppet 4 or later is required for this module.

If you have earlier Puppet versions use code from the 3.x tags.

### Beginning with network

Include the main class to be able to manage via Hiera the network resources handled by the module:

    include network
    
This does nothing by default, but allows to configure network resources with Hiera data like:

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


## Backwards compatibility


## Limitations


## Development

