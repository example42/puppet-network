# This class manages networking on different Operating systems
# It provives entry points to define, via Hiera data, hashes of
# interfaces, routes, rules and tables.
# The version 4 of this module also introduces backward incompatible
# defines to manage such objects, but allows to use previous style
# syntax by setting to true the telegant legacy params.
# With default settings with class does not manage any resource.

# @summary Data entrypoint for different network related defines
#
# @param hostname If set the network::hostname class is included and the
#   system's hostname configured
#
# @param host_conf_template The .epp or .erb template to use as content
#   of the /etc/host.conf file. If undef (as default) the file is not managed.
# @param host_conf_options A custom hash of options to use inside the
#   host_conf_template to parametrise values to interpolate.
#   In a .epp template refer to them with <%= $options['key'] %>
#   In a .erb template refer to them with <%= @host_conf_options['key'] %>
#
# @param nsswitch_conf_template The .epp or .erb template to use as content
#   of the /etc/nsswitch file. If undef (as default) the file is not managed.
# @param nsswitch_conf_options A custom hash of options to use inside the
#   nsswitch_conf_template to parametrise values to interpolate.
#   In a .epp template refer to them with <%= $options['key'] %>
#   In a .erb template refer to them with <%= @nsswitch_conf_options['key'] %>
#
# @param interfaces_hash An hash of interfaces to configure using the old
#   v3 compatible define network::legacy::interface.
#   The lookup method is based on the $hiera_merge parameter.
#   This is a deprecated parameter used for version 3 backwards compatibility.
# @param interfaces An hash of interfaces to configure.
#   This is not actually a class parameter, but a key looked up using the
#   merge behaviour configured via the $interfaces_merge_behaviour parameter.
#   The define network::interface is declared for each element of this hash.
# @param interfaces_merge_behaviour Defines the lookup method to use to
#   retrieve via hiera the $interfaces_hash
# @param interfaces_defaults An hash of default settings to merge with
#   the settings of each element of the $interfaces_hash
#   Useful to consolidate duplicated data in Hiera.
#
# @param routes_hash An hash of routes to configure using the old
#   v3 compatible define network::legacy::route.
#   The lookup method is based on the $hiera_merge parameter.
#   This is a deprecated parameter used for version 3 backwards compatibility.
# @param routes An hash of routes to configure.
#   This is not actually a class parameter, but a key looked up using the
#   merge behaviour configured via $routes_merge_behaviour.
#   The define network::route is declared for each element of this hash.
# @param routes_merge_behaviour Defines the lookup method to use to
#   retrieve via hiera the $routes_hash
# @param routes_defaults An hash of default settings to merge with
#   the settings of each element of the $routes_hash
#
# @param rules_hash An hash of rules to configure using the old
#   v3 compatible define network::legacy::rule.
#   The lookup method is based on the $hiera_merge parameter.
#   This is a deprecated parameter used for version 3 backwards compatibility.
# @param rules An hash of rules to configure.
#   This is not actually a class parameter, but a key looked up using the
#   merge behaviour configured via $rules_merge_behaviour.
#   The define network::rule is declared for each element of this hash.
# @param rules_merge_behaviour Defines the lookup method to use to
#   retrieve via hiera the $rules_hash
# @param rules_defaults An hash of default settings to merge with
#   the settings of each element of the $rules_hash
#
# @param tables_hash An hash of tables to configure using the old
#   v3 compatible define network::legacy::table.
#   The lookup method is based on the $hiera_merge parameter.
#   This is a deprecated parameter used for version 3 backwards compatibility.
# @param tables An hash of tables to configure.
#   This is not actually a class parameter, but a key looked up using the
#   merge behaviour configured via $tables_merge_behaviour.
#   The define network::table is declared for each element of this hash.
# @param tables_merge_behaviour Defines the lookup method to use to
#   retrieve via hiera the $tables_hash
# @param tables_defaults An hash of default settings to merge with
#   the settings of each element of the $tables_hash
#
# @param service_restart_exec The command to use to restart network
#   service when configuration changes occurs. Used with the default
#   setting for $config_file_notify
# @param config_file_notify The Resource to trigger when a configuration
#   change occurs. Default is Exec[$service_restart_exec], set to undef
#   or false or an empty string to not add any notify param on
#   config files resources (so no network change is automatically applied)
#   Note that if you configure a custom resource reference you must provide it
#   in your own profiles.
# @param config_file_per_interface If to configure interfaces in a single file
#   or having a single configuration file for each interface.
#   Default is true whenever a single file per interface is supported.
# @param hiera_merge If to use hash merge lookup for legacy <resource>s_hash 
#   parameters.
#   This is a deprecated parameter used for version 3 backwards compatibility.
class network (
  Optional[String] $hostname = undef,

  Optional[String]                    $host_conf_template = undef,
  Hash                                $host_conf_options  = {},

  Optional[String]                $nsswitch_conf_template = undef,
  Hash                            $nsswitch_conf_options  = {},

  Boolean $use_netplan                                    = false,
  # This "param" is looked up in code according to interfaces_merge_behaviour
  # Optional[Hash]              $interfaces               = undef,
  Enum['first','hash','deep'] $interfaces_merge_behaviour = 'first',
  Hash                        $interfaces_defaults        = {},

  # This "param" is looked up in code according to routes_merge_behaviour
  # Optional[Hash]              $routes                   = undef,
  Enum['first','hash','deep'] $routes_merge_behaviour     = 'first',
  Hash                        $routes_defaults            = {},

  # This "param" is looked up in code according to rules_merge_behaviour
  # Optional[Hash]              $rules                    = undef,
  Enum['first','hash','deep'] $rules_merge_behaviour      = 'first',
  Hash                        $rules_defaults             = {},

  # This "param" is looked up in code according to tables_merge_behaviour
  # Optional[Hash]              $tables                   = undef,
  Enum['first','hash','deep'] $tables_merge_behaviour     = 'first',
  Hash                        $tables_defaults            = {},

  # Legacy Params
  Hash $interfaces_hash                                   = {},
  Hash $routes_hash                                       = {},
  Hash $rules_hash                                        = {},
  Hash $tables_hash                                       = {},
  String $service_restart_exec                            = 'service network restart',
  Variant[Resource,String[0,0],Undef,Boolean] $config_file_notify  = true,
  Variant[Resource,String[0,0],Undef,Boolean] $config_file_require = undef,
  Boolean $config_file_per_interface                     = true,
  Boolean $hiera_merge                                   = false,
) {

  $manage_config_file_notify = $config_file_notify ? {
    true    => "Exec[${service_restart_exec}]",
    false   => undef,
    ''      => undef,
    undef   => undef,
    default => $config_file_notify,
  }
  $manage_config_file_require  = $config_file_require ? {
    true    => undef,
    false   => undef,
    ''      => undef,
    undef   => undef,
    default => $config_file_require,
  }

  # Exec to restart interfaces
  exec { $service_restart_exec :
    command     => $service_restart_exec,
    alias       => 'network_restart',
    refreshonly => true,
    path        => $::path,
  }

  if $hostname {
    contain '::network::hostname'
  }

  # Manage /etc/host.conf if $host_conf_template is set
  if $host_conf_template {
    $host_conf_template_type=$host_conf_template[-4,4]
    $host_conf_content = $host_conf_template_type ? {
      '.epp'  => epp($host_conf_template,{ options => $host_conf_options }),
      '.erb'  => template($host_conf_template),
      default => template($host_conf_template),
    }
    file { '/etc/host.conf':
      ensure  => present,
      content => $host_conf_content,
      notify  => $manage_config_file_notify,
    }
  }

  # Manage /etc/nsswitch.conf if $nsswitch_conf_template is set
  if $nsswitch_conf_template {
    $nsswitch_conf_template_type=$nsswitch_conf_template[-4,4]
    $nsswitch_conf_content = $nsswitch_conf_template_type ? {
      '.epp'  => epp($nsswitch_conf_template,{ options => $nsswitch_conf_options}),
      '.erb'  => template($nsswitch_conf_template),
      default => template($nsswitch_conf_template),
    }
    file { '/etc/nsswitch.conf':
      ensure  => present,
      content => $nsswitch_conf_content,
      notify  => $manage_config_file_notify,
    }
  }

  # Declare network interfaces based on network::interfaces
  $interfaces = lookup('network::interfaces',Hash,$interfaces_merge_behaviour,{})
  $interfaces.each |$k,$v| {
    network::interface { $k:
      * => $interfaces_defaults + $v,
    }
  }
  # Declare network::legacy::interface based on legacy network::interfaces_hash
  $legacy_interfaces_hash = $hiera_merge ? {
    true  => lookup('network::interfaces_hash',Hash,'hash',{}),
    false => $interfaces_hash,
  }
  $legacy_interfaces_hash.each |$k,$v| {
    network::legacy::interface { $k:
      * => $interfaces_defaults + $v,
    }
  }

  # Declare network routes based on network::routes
  $routes = lookup('network::routes',Hash,$routes_merge_behaviour,{})
  $routes.each |$k,$v| {
    network::route { $k:
      * => $routes_defaults + $v,
    }
  }
  # Declare network::legacy::route based on legacy network::routes_hash
  $legacy_routes_hash = $hiera_merge ? {
    true  => lookup('network::routes_hash',Hash,'hash',{}),
    false => $routes_hash,
  }
  $legacy_routes_hash.each |$k,$v| {
    network::legacy::route { $k:
      * => $routes_defaults + $v,
    }
  }


  # Declare network rules based on network::rules
  $rules = lookup('network::rules',Hash,$rules_merge_behaviour,{})
  $rules.each |$k,$v| {
    network::rule { $k:
      * => $rules_defaults + $v,
    }
  }
  # Declare network::legacy::rule based on legacy network::rules_hash
  $legacy_rules_hash = $hiera_merge ? {
    true  => lookup('network::rules_hash',Hash,'hash',{}),
    false => $rules_hash,
  }
  $legacy_rules_hash.each |$k,$v| {
    network::legacy::rule { $k:
      * => $rules_defaults + $v,
    }
  }


  # Declare network tables based on network::tables
  $tables = lookup('network::tables',Hash,$tables_merge_behaviour,{})
  $tables.each |$k,$v| {
    network::table { $k:
      * => $tables_defaults + $v,
    }
  }
  # Declare network::legacy::table based on legacy network::tables_hash
  $legacy_tables_hash = $hiera_merge ? {
    true  => lookup('network::tables_hash',Hash,'hash',{}),
    false => $tables_hash,
  }
  $legacy_tables_hash.each |$k,$v| {
    network::legacy::table { $k:
      * => $tables_defaults + $v,
    }
  }

}
