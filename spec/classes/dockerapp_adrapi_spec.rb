require 'spec_helper'

describe 'dockerapp_adrapi' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:params) do
        {
          version: '1.4.1',
          service_name: 'adrapi_test',
        }
      end

      it { is_expected.to compile }
      it { is_expected.to contain_class('docker') }
      it { is_expected.to contain_file('/srv/application-data/adrapi_test') }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test') }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json') }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/security.json') }
      it { is_expected.to contain_file('/srv/application-lib/adrapi_test') }
      it { is_expected.to contain_file('/srv/application-log/adrapi_test') }
      it { is_expected.to contain_file('/srv/scripts/adrapi_test') }
    end
  end
end
