require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'network::interface' do

  let(:title) { 'eth0' }
  let(:node) { 'rspec.example42.com' }
  let(:facts) { { :arch => 'i386' , :osfamily => 'Solaris', :operatingsystemmajrelease => '11' } }
  let(:params) {
    { 'enable'       =>  true,
      'ipaddress'    =>  '10.42.42.42',
      'netmask'      =>  '255.255.255.0',
    }
  }

  describe 'Test network::interface on Solaris' do
    it 'should create a hostname file' do
      should contain_file('hostname iface eth0').with_content(/10.42.42.42/)
    end
    it 'should restart network service' do
      should contain_service('svc:/network/physical:default').with_ensure('running')
    end
  end

end

