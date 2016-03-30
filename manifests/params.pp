# Class: network::params
#
# Defines all the variables used in the module.
#
class network::params {

  $service_restart_exec = $::osfamily ? {
    'Debian'  => '/sbin/ifdown -a && /sbin/ifup -a',
    'Solaris' => '/usr/sbin/svcadm restart svc:/network/physical:default',
    default   => 'service network restart',
  }

  $config_file_path = $::osfamily ? {
    'Debian' => '/etc/network/interfaces',
    'RedHat' => '/etc/sysconfig/network-scripts/ifcfg-eth0',
    'Suse'   => '/etc/sysconfig/network/ifcfg-eth0',
    default  => undef,
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
    'Debian' => '/etc/network',
    'Redhat' => '/etc/sysconfig/network-scripts',
    'Suse'   => '/etc/sysconfig/network',
    default  => undef,
  }

  case $::osfamily {
    'Debian','RedHat','Amazon','Suse', 'Solaris': { }
    default: {
      fail("${::operatingsystem} not supported.")
    }
  }
}
