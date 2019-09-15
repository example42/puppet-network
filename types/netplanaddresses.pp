type Network::Netplanaddresses = Array[
  Variant[
    Stdlib::IP::Address::V4::CIDR,
    Variant[
      Stdlib::IP::Address::V6::Full,
      Stdlib::IP::Address::V6::Compressed,
      Stdlib::IP::Address::V6::Alternative,
    ]
  ]
]
