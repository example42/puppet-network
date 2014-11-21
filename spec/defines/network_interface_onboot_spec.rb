require "spec_helper"

NIC_CONFIG = '/etc/sysconfig/network-scripts/ifcfg-eth0'

describe 'network::interface' do
  let(:title) { 'eth0' }

  context 'RedHat OS' do
    let(:facts) {{ :osfamily => 'RedHat' }}

    context 'onboot set to yes' do
      let(:params) {{  :onboot => 'yes' }}

      it do
        should contain_file(NIC_CONFIG).with_content(/ONBOOT="yes"/)
      end
    end

    context 'onboot set to no' do
      let(:params) {{ :onboot => 'no' }}

      it do
        should contain_file(NIC_CONFIG).with_content(/ONBOOT="no"/)
      end
    end

    context 'onboot not defined' do
      context 'enable set to true' do
        let(:params) {{ :enable => true }}

        it do
          should contain_file(NIC_CONFIG).with_content(/ONBOOT="yes"/)
        end
      end

      context 'enable set to false' do
        let(:params) {{ :enable => false }}

        it do
          should contain_file(NIC_CONFIG).with_content(/ONBOOT="no"/)
        end
      end
    end
  end
end
