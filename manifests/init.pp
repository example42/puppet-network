# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include network
class network (
  Optional[String] $hostname = undef,

  # This "param" is looked up in code according to interfaces_merge_behaviour
  # Optional[Hash]              $interfaces_hash            = undef,
  Boolean                     $interfaces_legacy          = false,
  Enum['first','hash','deep'] $interfaces_merge_behaviour = 'first',
  Hash                        $interfaces_defaults        = {},

  # This "param" is looked up in code according to routes_merge_behaviour
  # Optional[Hash]              $routes_hash                = undef,
  Boolean                     $routes_legacy              = false,
  Enum['first','hash','deep'] $routes_merge_behaviour     = 'first',
  Hash                        $routes_defaults            = {},

  # This "param" is looked up in code according to rules_merge_behaviour
  # Optional[Hash]              $rules_hash                 = undef,
  Boolean                     $rules_legacy               = false,
  Enum['first','hash','deep'] $rules_merge_behaviour      = 'first',
  Hash                        $rules_defaults             = {},

  # This "param" is looked up in code according to tables_merge_behaviour
  # Optional[Hash]              $tables_hash                = undef,
  Boolean                     $tables_legacy          = false,
  Enum['first','hash','deep'] $tables_merge_behaviour = 'first',
  Hash                        $tables_defaults        = {},

  String $service_restart_exec = 'service network restart',
  Variant[Resource,String] $config_file_notify = 'class_default',
  Boolean $config_file_per_interface           = true,
) {

  $manage_config_file_notify = $config_file_notify ? {
    'class_default' => "Exec[${service_restart_exec}]",
    'undef'         => undef,
    ''              => undef,
    undef           => undef,
    default         => $config_file_notify,
  }
  exec { $service_restart_exec :
    command     => $service_restart_exec,
    alias       => 'network_restart',
    refreshonly => true,
    path        => '/bin:/sbin:/usr/bin:/usr/sbin',
  }  
  if $hostname {
    contain '::network::hostname'
  }

  # Declare network interfaces based on network::interfaces_hash
  $interfaces_hash = lookup('network::interfaces_hash',Hash,$interfaces_merge_behaviour,{})
  $interfaces_hash.each |$k,$v| {
    if $interfaces_legacy {
      network::legacy::interface { $k:
        * => $interfaces_defaults + $v,
      }
    } else {
      network::interface { $k:
        * => $interfaces_defaults + $v,
      }
    }
  }

  # Declare network routes based on network::routes_hash
  $routes_hash = lookup('network::routes_hash',Hash,$routes_merge_behaviour,{})
  $routes_hash.each |$k,$v| {
    if $routes_legacy {
      network::legacy::route { $k:
        * => $routes_defaults + $v,
      }
    } else {
      network::route { $k:
        * => $routes_defaults + $v,
      }
    }
  }

  # Declare network rules based on network::rules_hash
  $rules_hash = lookup('network::rules_hash',Hash,$rules_merge_behaviour,{})
  $rules_hash.each |$k,$v| {
    if $rules_legacy {
      network::legacy::rule { $k:
        * => $rules_defaults + $v,
      }
    } else {
      network::rule { $k:
        * => $rules_defaults + $v,
      }
    }
  }

  # Declare network tables based on network::tables_hash
  $tables_hash = lookup('network::tables_hash',Hash,$tables_merge_behaviour,{})
  $tables_hash.each |$k,$v| {
    if $tables_legacy {
      network::legacy::routing_table { $k:
        * => $tables_defaults + $v,
      }
    } else {
      network::table { $k:
        * => $tables_defaults + $v,
      }
    }
  }

}
