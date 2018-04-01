require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'network::interface' do

  context 'Test network::interface on RedHat' do

    let(:title) { 'eth0' }
    let(:node) { 'rspec.example42.com' }
    let(:facts) { { :architecture => 'x86_64', :osfamily => 'RedHat', :operatingsystem => 'RedHat' } }
    let(:params) {
      { 'enable'       =>  true,
        'ipaddress'    =>  '10.42.42.42',
      }
    }

    it {
      is_expected.to contain_file('/etc/sysconfig/network-scripts/ifcfg-eth0').with_ensure('present')
    }

    it {
      is_expected.to contain_file('/etc/sysconfig/network-scripts/ifcfg-eth0').with_content(/IPADDR=\"10.42.42.42\"/)
    }

    it {
      is_expected.to contain_file('/etc/sysconfig/network-scripts/ifcfg-eth0').with_content(/ONBOOT=\"yes\"/)
    }

  end

  context 'Test network:interface on RedHat with multiple IPs' do
    let(:title) { 'eth0' }
    let(:node) { 'rspec.example42.com' }
    let(:facts) { { :architecture => 'x86_64', :osfamily => 'RedHat', :operatingsystem => 'RedHat' } }
    let(:params) {
      { 'enable'       =>  true,
        'ipaddress'    =>  ['192.168.0.1','192.168.0.2'],
      }
    }

    it {
      is_expected.to contain_file('/etc/sysconfig/network-scripts/ifcfg-eth0').with_ensure('present')
    }

    it {
      is_expected.to contain_file('/etc/sysconfig/network-scripts/ifcfg-eth0').with_content(/IPADDR1=\"192.168.0.1\"/)
    }

    it {
      is_expected.to contain_file('/etc/sysconfig/network-scripts/ifcfg-eth0').with_content(/IPADDR2=\"192.168.0.2\"/)
    }

    it {
      is_expected.to contain_file('/etc/sysconfig/network-scripts/ifcfg-eth0').with_content(/ONBOOT=\"yes\"/)
    }

  end

end
