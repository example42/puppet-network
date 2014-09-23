require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'network::interface' do

  let(:title) { 'eth0' }
  let(:node) { 'rspec.example42.com' }
  let(:facts) { { :arch => 'i386' , :osfamily => 'RedHat' } }
  let(:params) {
    { 'enable'       =>  true,
      'ipaddress'    =>  '10.42.42.42',
    }
  }

  describe 'Test network::interface on RedHat' do
    it 'should create a ifcfg file' do
      should contain_file('/etc/sysconfig/network-scripts/ifcfg-eth0').with_ensure('present')
    end
    it 'should populate the ifcfg file with correct IP address' do
      should contain_file('/etc/sysconfig/network-scripts/ifcfg-eth0').with_content(/IPADDR=\"10.42.42.42\"/)
    end
    it 'should populate the ifcfg file with onboot=yes' do
      should contain_file('/etc/sysconfig/network-scripts/ifcfg-eth0').with_content(/ONBOOT=\"yes\"/)
    end
  end

end

