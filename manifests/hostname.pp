# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include network::hostname
class network::hostname (
  Optional[String] $hostname_file_template = undef,
  Boolean          $hostname_legacy        = false,
  Hash             $options                = {},
) {

  $hostname_default_template = $hostname_legacy ? {
    true  => "network/legacy/hostname-${::osfamily}.erb",
    false => "network/hostname-${::osfamily}.erb",
  }
  $file_template = pick($hostname_file_template,$hostname_default_template)
  $manage_hostname = pick($::network::hostname,$::fqdn)

  if $::osfamily == 'RedHat' {
    file { '/etc/sysconfig/network':
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => template($file_template),
      notify  => $::network::manage_config_file_notify,
    }
    case $::lsbmajdistrelease {
      '7': {
        exec { 'sethostname':
          command => "/usr/bin/hostnamectl set-hostname ${manage_hostname}",
          unless  => "/usr/bin/hostnamectl status | grep 'Static hostname: ${manage_hostname}'",
        }
      }
      default: {}
    }
  }

  if $::osfamily == 'Debian' {
    file { '/etc/hostname':
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => template($file_template),
      notify  => $::network::manage_config_file_notify,
    }
  }

  if $::osfamily == 'Suse' {
    file { '/etc/HOSTNAME':
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => inline_template("<%= @manage_hostname %>\n"),
      notify  => Exec['sethostname'],
    }
    exec { 'sethostname':
      command => "/bin/hostname ${manage_hostname}",
      unless  => "/bin/hostname -f | grep ${manage_hostname}",
    }
  }

  if $::osfamily == 'Solaris' {
    file { '/etc/nodename':
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => inline_template("<%= @manage_hostname %>\n"),
      notify  => Exec['sethostname'],
    }
    exec { 'sethostname':
      command => "/usr/bin/hostname ${manage_hostname}",
      unless  => "/usr/bin/hostname | /usr/bin/grep ${manage_hostname}",
    }
  }
}
