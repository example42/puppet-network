require "spec_helper"

NIC_CONFIG = '/etc/sysconfig/network-scripts/ifcfg-eth0'

describe 'network::interface' do

  let(:title) { 'eth0' }

  context 'RedHat OS' do

    let(:facts) {{ :architecture => 'x86_64', :osfamily => 'RedHat', :operatingsystem => 'RedHat' }}

    context 'onboot set to yes' do

      let(:params) {{  :onboot => 'yes' }}

      it {
        is_expected.to contain_file(NIC_CONFIG).with_content(/ONBOOT="yes"/)
      }

    end

    context 'onboot set to no' do

      let(:params) {{ :onboot => 'no' }}

      it {
        is_expected.to contain_file(NIC_CONFIG).with_content(/ONBOOT="no"/)
      }

    end

    context 'onboot not defined' do

      context 'enable set to true' do

        let(:params) {{ :enable => true }}

        it {
          is_expected.to contain_file(NIC_CONFIG).with_content(/ONBOOT="yes"/)
        }

      end

      context 'enable set to false' do

        let(:params) {{ :enable => false }}

        it {
          is_expected.to contain_file(NIC_CONFIG).with_content(/ONBOOT="no"/)
        }

      end

    end

  end

end
