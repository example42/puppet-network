# Class: network::params
#
# Defines all the variables used in the module.
#
class network::params {

  $package_name = $::osfamily ? {
    default => 'network',
  }

  $service_name = $::osfamily ? {
    default => 'network',
  }

  $config_file_path = $::osfamily ? {
    default => '/etc/network/network.conf',
  }

  $config_file_mode = $::osfamily ? {
    default => '0644',
  }

  $config_file_owner = $::osfamily ? {
    default => 'root',
  }

  $config_file_group = $::osfamily ? {
    default => 'root',
  }

  $config_dir_path = $::osfamily ? {
    default => '/etc/network',
  }

  case $::osfamily {
    'Debian','RedHat','Amazon': { }
    default: {
      fail("${::operatingsystem} not supported. Review params.pp for extending support.")
    }
  }
}
