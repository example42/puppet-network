require "spec_helper"

NIC_CONFIG = '/etc/sysconfig/network-scripts/ifcfg-eth0'

describe 'network::interface' do

  let(:title) { 'eth0' }

  context 'RedHat OS' do

    let(:facts) {{ :architecture => 'x86_64', :osfamily => 'RedHat', :operatingsystem => 'RedHat' }}

    context 'defroute set to true' do

      let(:params) {{ :defroute => true }}

      it {
        is_expected.to contain_file(NIC_CONFIG).with_content(/DEFROUTE="yes"/)
      }

    end

    context 'defroute set to false' do

      let(:params) {{ :defroute => false }}

      it {
        is_expected.to contain_file(NIC_CONFIG).with_content(/DEFROUTE="no"/)
      }

    end

    context 'defroute not defined' do

      let(:params) {{}}

      it {
        is_expected.to contain_file(NIC_CONFIG).without_content(/DEFROUTE/)
      }

    end

  end

end
