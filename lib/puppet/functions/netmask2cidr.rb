require 'ipaddr'
Puppet::Functions.create_function(:netmask2cidr, Puppet::Functions::InternalFunction) do
  dispatch :single do
    param 'Stdlib::IP::Address', :netmask
  end
  def single(netmask)
    result = IPAddr.new(netmask).to_i.to_s(2).count("1")
  end
end
