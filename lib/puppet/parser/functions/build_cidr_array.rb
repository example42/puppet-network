module Puppet::Parser::Functions
  newfunction(:build_cidr_array, :type => :rvalue) do |args|
    unless args.length == 1 then
      raise Puppet::ParseError, ("netmask_to_masklen(): wrong number of arguments (#{args.length}; must be 1)")
    end
    new_array = []
    args[0].each do |item|
      begin
        new_array.push(IPAddr.new(item).to_i.to_s(2).count('1'))
      rescue ArgumentError => e
        raise Puppet::ParseError, (e)
      end
    end
    new_array
  end
end
