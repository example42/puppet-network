# == Definition: network::routing_table
#
# Configures /etc/iproute2/rt_tables
#
# === Parameters:
#
#   $table_id - required
#
# === Actions:
#
# Adds routing table id and name to /etc/iproute2/rt_tables
#
# === Sample Usage:
#
#   network::routing_table { 'vlan22':
#     table_id => '200',
#   }
#
# === Authors:
#
# Marcus Furlong <furlongm@gmail.com>
#

define network::routing_table (
  String $table_id,
  String $table = $name
  ) {

  if ! defined(Concat['/etc/iproute2/rt_tables']) {
    concat { '/etc/iproute2/rt_tables':
      owner => 'root',
      group => 'root',
      mode  => '0644',
    }

    concat::fragment { 'rt_tables-base':
      target => '/etc/iproute2/rt_tables',
      source => 'puppet:///modules/network/legacy/rt_tables',
    }
  }

  concat::fragment { "rt_tables-${table}":
    target  => '/etc/iproute2/rt_tables',
    content => "${table_id}\t${table}\n",
  }
} # define network::routing_table
