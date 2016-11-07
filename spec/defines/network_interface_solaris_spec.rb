require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'network::interface' do

  context 'Test network::interface on Solaris' do

    let(:title) { 'eth0' }
    let(:node) { 'rspec.example42.com' }
    let(:facts) { { :architecture => 'i386' , :osfamily => 'Solaris', :operatingsystem => 'Solaris', :operatingsystemrelease => '11.3', :operatingsystemmajrelease => '11' } }
    let(:params) {
      { 'enable'       =>  true,
        'ipaddress'    =>  '10.42.42.42',
        'netmask'      =>  '255.255.255.0',
      }
    }

    it {
      is_expected.to contain_file('hostname iface eth0').with_content(/10.42.42.42/)
    }

    it {
      is_expected.to contain_host(node).with_ip('10.42.42.42')
    }

    it {
      is_expected.to contain_service('svc:/network/physical:default').with_ensure('running')
    }

  end

end
