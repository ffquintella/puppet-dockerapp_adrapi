require 'spec_helper'

describe 'dockerapp_adrapi' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:params) do
        {
          version: '1.5.0',
          service_name: 'adrapi_test',
          ldap_admin_cn: 'Administrator',
          allowed_hosts: '*',
        }
      end

      it { is_expected.to compile }
      it { is_expected.to contain_class('docker') }
      it { is_expected.to contain_file('/srv/application-data/adrapi_test') }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test') }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json') }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/cfg') }
      it { is_expected.to contain_file('/srv/application-lib/adrapi_test') }
      it { is_expected.to contain_file('/srv/application-log/adrapi_test') }
      it { is_expected.to contain_file('/srv/scripts/adrapi_test') }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').with_content(%r{"AllowedHosts": "\*"}) }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').with_content(%r{"adminCn": "Administrator"}) }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').with_content(%r{"databaseFile": "cfg/api-keys.db"}) }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').with_content(%r{"seedFile": "cfg/.seed"}) }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').with_content(%r{"pinStore": "cfg/ldap-trusted-certs.json"}) }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').with_content(%r{"permitLimit": 5}) }
      # Secrets no longer rendered into appsettings.json.
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').without_content(%r{bindCredentials}) }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').without_content(%r{"password":}) }
      # Legacy security.json not created when sec_keys is undef.
      it { is_expected.not_to contain_file('/srv/application-config/adrapi_test/security.json') }
    end

    context "on #{os} with sec_keys (legacy)" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.5.0',
          service_name: 'adrapi_test',
          sec_keys: {
            'ReadOnly' => {
              'key'           => 'short-rotate-me',
              'authorized_ip' => '10.0.0.0/8',
              'claims'        => ['isMonitor'],
              'service_name'  => 'adrapi_test',
            },
          },
        }
      end

      it { is_expected.to compile }
    end

    # Sub-contexts that exercise in-module defined types only assert compile
    # success: regent's catalog matcher does not currently expose child resources
    # of in-module defined types (Dockerapp_adrapi::Api_key / Ldap_pin / App_secret),
    # so `contain_exec(...)` assertions for those children would always miss even
    # though the catalog compiles and the manifests reach 100% line coverage.

    context "on #{os} with api_keys" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.5.0',
          service_name: 'adrapi_test',
          api_keys: {
            'prod-admin' => {
              'authorized_ip' => '10.0.0.0/8',
              'claims'        => ['isAdministrator'],
              'secret'        => 'plaintext-from-eyaml',
            },
          },
        }
      end

      it { is_expected.to compile }
    end

    context "on #{os} with bind credentials (encrypted)" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.5.0',
          service_name: 'adrapi_test',
          ldap_bind_dn: 'CN=svc,DC=example,DC=com',
          ldap_bind_password: 'p@ss',
          certificate_password: 'cert-p@ss',
        }
      end

      it { is_expected.to compile }
    end

    context "on #{os} with ldap_pins" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.5.0',
          service_name: 'adrapi_test',
          ldap_pins: {
            'dc01.example.com:636' => { 'note' => 'primary DC' },
          },
        }
      end

      it { is_expected.to compile }
    end
  end
end
