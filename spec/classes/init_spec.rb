require 'spec_helper'

describe 'network' do

  context 'Supported OS - ' do
    ['Debian', 'RedHat'].each do |osfamily|
      describe "#{osfamily} configuration via custom template" do
        let(:params) {{
          :config_file_template     => 'network/spec.conf',
          :config_file_options_hash => { 'opt_a' => 'value_a' },
        }}
        let(:facts) {{
          :osfamily => osfamily,
        }}
        it { should contain_file('network.conf').with_content(/This is a template used only for rspec tests/) }
        it 'should generate a template that uses custom options' do
          should contain_file('network.conf').with_content(/value_a/)
        end
      end

      describe "#{osfamily} configuration via custom content" do
        let(:params) {{
          :config_file_content    => 'my_content',
        }}
        let(:facts) {{
          :osfamily => osfamily,
        }}
        it { should contain_file('network.conf').with_content(/my_content/) }
      end

      describe "#{osfamily} configuration via custom source file" do
        let(:params) {{
          :config_file_source => "puppet:///modules/network/spec.conf",
        }}
        let(:facts) {{
          :osfamily => osfamily,
        }}
        it { should contain_file('network.conf').with_source('puppet:///modules/network/spec.conf') }
      end

      describe "#{osfamily} configuration via custom source dir" do
        let(:params) {{
          :config_dir_source => 'puppet:///modules/network/tests/',
          :config_dir_purge => true
        }}
        let(:facts) {{
          :osfamily => osfamily,
        }}
        it { should contain_file('network.dir').with_source('puppet:///modules/network/tests/') }
        it { should contain_file('network.dir').with_purge('true') }
        it { should contain_file('network.dir').with_force('true') }
      end

      describe "#{osfamily} service restart disabling on config file change" do
        let(:params) {{
          :config_file_notify => '',
          :config_file_source => "puppet:///modules/network/spec.conf",
        }}
        let(:facts) {{
          :osfamily => osfamily,
        }}
        it 'should automatically restart the service when files change' do
          should contain_file('network.conf').without_notify
        end
      end

    end
  end

  context 'RedHat family specific' do
    describe "RedHat service restart on config file change (default)" do
      let(:facts) {{
        :osfamily => 'RedHat',
      }}
      let(:params) {{
        :config_file_source => "puppet:///modules/network/spec.conf",
      }}
      it 'should automatically restart the service when files change' do
        should contain_file('network.conf').with_notify("Exec[service network restart]")
      end
    end
  end

  context 'Debian family specific' do
    describe "Debian service restart on config file change (default)" do
      let(:facts) {{
        :osfamily => 'Debian',
      }}
      let(:params) {{
        :config_file_source => "puppet:///modules/network/spec.conf",
      }}
      it 'should automatically restart the service when files change' do
        should contain_file('network.conf').with_notify("Exec[/sbin/ifdown -a && /sbin/ifup -a]")
      end
    end
  end

  context 'Unsupported OS - ' do
    describe 'Not supported operating systems should throw and error' do
      let(:facts) {{
        :osfamily        => 'Solaris',
        :operatingsystem => 'Nexenta',
      }}
      it 'should fail' do
        expect { should compile }.to raise_error()
      end
    end
  end

end

