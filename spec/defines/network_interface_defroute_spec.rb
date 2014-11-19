require "spec_helper"

NIC_CONFIG = '/etc/sysconfig/network-scripts/ifcfg-eth0'

describe 'network::interface' do
  let(:title) { 'eth0' }

  context 'RedHat OS' do
    let(:facts) {{ :osfamily => 'RedHat' }}

    context 'defroute set to true' do
      let(:params) {{ :defroute => true }}

      it do
        should contain_file(NIC_CONFIG).with_content(/DEFROUTE="yes"/)
      end
    end

    context 'defroute set to false' do
      let(:params) {{ :defroute => false }}

      it do
        should contain_file(NIC_CONFIG).with_content(/DEFROUTE="no"/)
      end
    end

    context 'defroute not defined' do
      let(:params) {{}}

      it do
        should contain_file(NIC_CONFIG).without_content(/DEFROUTE/)
      end
    end
  end
end
