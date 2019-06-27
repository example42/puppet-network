# Define network::netplan
#
# Define to manage a netplan configuration file
#
define network::netplan (
  String $config_file_name = "50-${title}-yaml",
  Enum['present','absent'] $ensure = 'present',
  String $renderer = 'networkd',
  Numeric $version         = 2,

  Stdlib::Absolutepath $config_dir_path  = '/etc/netplan',

  Hash $ethernets          = {},
  Hash $wifis              = {},
  Hash $bridges            = {},
  Hash $bonds              = {},
  Hash $tunnels            = {},
  Hash $vlans              = {},

) {

  $netplan_data = {
    'network' => {
      'version'   => $version,
      'renderer'  => $renderer,
      'ethernets' => $ethernets,
      'wifis'     => $wifis,
      'bridges'   => $bridges,
      'bonds'     => $bonds,
      'tunnels'   => $tunnels,
      'vlans'     => $vlans,
    }
  }

  file { "${config_dir_path}/${config_file_name}":
    ensure  => $ensure,
    content => to_yaml($netplan_data),
  }
}
