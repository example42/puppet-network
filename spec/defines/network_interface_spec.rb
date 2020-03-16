require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

# set variables for resources
NIC_PATH = '/etc/sysconfig/network-scripts/ifcfg-eth0'
NIC_CONFIG = 'interface-eth0'
RULE_CONFIG = 'rule-eth0'

describe 'network::interface' do

  context 'Test network::interface on RedHat' do

    let(:title) { 'eth0' }
    let(:node) { 'rspec.example42.com' }
    let(:facts) { { :architecture => 'x86_64', :osfamily => 'RedHat', :operatingsystem => 'RedHat' , :operatingsystemmajrelease => '7' } }
    let(:params) {
      { 'enable'                =>  true,
        'ipaddress'             =>  '10.42.42.42',
        'options_extra_redhat'  => {
          'IPV4_FAILURE_FATAL'  => 'yes',
        },
      }
    }

    it {
      is_expected.to contain_concat(NIC_PATH).with_ensure('present')
    }

    it {
      is_expected.to contain_concat_fragment(NIC_CONFIG).with_content(/IPADDR=\"10.42.42.42\"/)
    }

    it {
      is_expected.to contain_concat_fragment(NIC_CONFIG).with_content(/ONBOOT=\"yes\"/)
    }

    it {
      is_expected.to contain_concat_fragment(NIC_CONFIG).with_content(/IPV4_FAILURE_FATAL=\"yes\"/)
    }

  end

  context 'Test network:interface on RedHat with multiple IPs' do
    let(:title) { 'eth0' }
    let(:node) { 'rspec.example42.com' }
    let(:facts) { { :architecture => 'x86_64', :osfamily => 'RedHat', :operatingsystem => 'RedHat', :operatingsystemmajrelease => '7' } }
    let(:params) {
      { 'enable'       =>  true,
        'ipaddress'    =>  ['192.168.0.1','192.168.0.2'],
      }
    }

    it {
      is_expected.to contain_concat(NIC_PATH).with_ensure('present')
    }

    it {
      is_expected.to contain_concat_fragment(NIC_CONFIG).with_content(/IPADDR1=\"192.168.0.1\"/)
    }

    it {
      is_expected.to contain_concat_fragment(NIC_CONFIG).with_content(/IPADDR2=\"192.168.0.2\"/)
    }

    it {
      is_expected.to contain_concat_fragment(NIC_CONFIG).with_content(/ONBOOT=\"yes\"/)
    }

  end
end

describe 'network::rule' do

  context 'Test network:interface on RedHat 7 with multiple IP rules' do
    let(:title) { 'eth0' }
    let(:node) { 'rspec.example42.com' }
    let(:facts) { { :architecture => 'x86_64', :osfamily => 'RedHat', :operatingsystem => 'RedHat', :operatingsystemmajrelease => '7' } }
    let(:params) {
        { 'iprule' => ['from 192.168.22.0/24 lookup vlan22','from 192.168.24.0/24 lookup vlan22'],
          'family' => ['inet'],
      }
    }
    it {
        is_expected.to contain_file(RULE_CONFIG).with_content(/from 192.168.22.0\/24 lookup vlan22/)
    }

    it {
        is_expected.to contain_file(RULE_CONFIG).with_content(/from 192.168.24.0\/24 lookup vlan22/)
    }

  end

  context 'Test network:interface on RedHat 8 with multiple IP rules' do
    let(:title) { 'eth0' }
    let(:node) { 'rspec.example42.com' }
    let(:facts) { { :architecture => 'x86_64', :osfamily => 'RedHat', :operatingsystem => 'RedHat', :operatingsystemmajrelease => '8' } }
    let(:params) {
        { 'iprule' => ['from 192.168.22.0/24 lookup vlan22','from 192.168.24.0/24 lookup vlan22'],
          'family' => ['inet'],
      }
    }
    it {
        is_expected.to contain_concat_fragment(RULE_CONFIG).with_content(/ROUTING_RULE_1=\"from 192.168.22.0\/24 lookup vlan22\"/)
    }

    it {
        is_expected.to contain_concat_fragment(RULE_CONFIG).with_content(/ROUTING_RULE_2=\"from 192.168.24.0\/24 lookup vlan22\"/)
    }

  end

end
