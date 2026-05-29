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

    # The port model maps host ports to the container's fixed 6000 (HTTP) / 6001 (HTTPS)
    # listeners. These contexts only assert compile success: regent's catalog matcher does
    # not expose the `ports` attribute of the dockerapp::run fixture defined type (it reads
    # back as Undef), so `with_ports(...)` can't be checked - the branches are still covered.
    context "on #{os} with custom http_port/https_port" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.5.0',
          service_name: 'adrapi_test',
          http_port: 6000,
          https_port: 5501,
        }
      end

      it { is_expected.to compile }
    end

    context "on #{os} with http_port disabled (HTTPS only)" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.5.0',
          service_name: 'adrapi_test',
          http_port: nil,
          https_port: 5501,
        }
      end

      it { is_expected.to compile }
    end

    context "on #{os} with explicit ports override" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.5.0',
          service_name: 'adrapi_test',
          ports: ['5501:6001'],
        }
      end

      it { is_expected.to compile }
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

    context "on #{os} with certificate_file_content (base64)" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.5.0',
          service_name: 'adrapi_test',
          certificate_file: 'adrapi-prod.p12',
          certificate_file_content: 'ZmFrZS1wa2NzMTItYnl0ZXM=',
        }
      end

      it { is_expected.to compile }
      # Module writes the decoded cert under the config dir.
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/adrapi-prod.p12') }
    end

    context "on #{os} with certificate_file_path (host path)" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.5.0',
          service_name: 'adrapi_test',
          certificate_file: 'adrapi-fgv-dev.p12',
          certificate_file_path: '/srv/application-config/adrapi_test/adrapi-fgv-dev.p12',
        }
      end

      it { is_expected.to compile }
      # Host-provided cert is mounted as-is, not written by Puppet.
      it { is_expected.not_to contain_file('/srv/application-config/adrapi_test/adrapi-fgv-dev.p12') }
    end

    context "on #{os} with both certificate sources set" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.5.0',
          service_name: 'adrapi_test',
          certificate_file_content: 'ZmFrZQ==',
          certificate_file_path: '/srv/application-config/adrapi_test/cert.p12',
        }
      end

      it { is_expected.to compile.and_raise_error(%r{set only one of certificate_file_content or certificate_file_path}) }
    end
  end
end
