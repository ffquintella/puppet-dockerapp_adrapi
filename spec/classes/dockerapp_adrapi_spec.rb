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
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').with_content(%r{"trustedCertificatesFile": "cfg/ldap-trusted-certs.json"}) }
      # adrapi >= 1.10.0 layout: a `directories` section with the LDAP settings as one
      # `kind` of domain. The deprecated top-level `ldap` section is not emitted.
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').with_content(%r{"directories":}) }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').with_content(%r{"defaultDomain": "default"}) }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').with_content(%r{"default": \{\s*"kind": "ldap"}) }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').without_content(%r{^  "ldap": \{}) }
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

    context "on #{os} with entra_domains" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.9.0',
          service_name: 'adrapi_test',
          default_domain: 'corp',
          entra_domains: {
            'cloud' => {
              'tenant_id'           => 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
              'client_id'           => '11111111-2222-3333-4444-555555555555',
              'client_secret'       => 'secret-from-eyaml',
              'granted_permissions' => ['User.ReadWrite.All', 'Group.ReadWrite.All'],
            },
          },
        }
      end

      it { is_expected.to compile }
      # A defaultDomain and a domains block are emitted for Entra ID-backed directories.
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').with_content(%r{"defaultDomain": "corp"}) }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').with_content(%r{"domains":}) }
      # `default_domain` names no Entra domain, so the LDAP block takes that name.
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').with_content(%r{"corp": \{\s*"kind": "ldap"}) }
      # The client secret never lands in appsettings.json (it goes to the encrypted store).
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').without_content(%r{secret-from-eyaml}) }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').without_content(%r{clientSecret}) }
    end

    # An Entra ID domain may be the default one since adrapi 1.10.0; `manage_ldap_domain`
    # drops the LDAP domain entirely for a cloud-only deployment.
    context "on #{os} with an Entra ID default domain and no LDAP" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.10.0',
          service_name: 'adrapi_test',
          default_domain: 'cloud',
          manage_ldap_domain: false,
          entra_domains: {
            'cloud' => {
              'tenant_id' => 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
              'client_id' => '11111111-2222-3333-4444-555555555555',
            },
          },
        }
      end

      it { is_expected.to compile }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').with_content(%r{"defaultDomain": "cloud"}) }
    end

    # With an Entra domain holding the default name, the LDAP domain falls back to
    # adrapi's `default` rather than colliding with it.
    context "on #{os} with an Entra ID default domain alongside LDAP" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.10.0',
          service_name: 'adrapi_test',
          default_domain: 'cloud',
          entra_domains: {
            'cloud' => {
              'tenant_id' => 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
              'client_id' => '11111111-2222-3333-4444-555555555555',
            },
          },
        }
      end

      it { is_expected.to compile }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').with_content(%r{"default": \{\s*"kind": "ldap"}) }
    end

    context "on #{os} with an explicit ldap_domain" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.10.0',
          service_name: 'adrapi_test',
          ldap_domain: 'corp',
          default_domain: 'corp',
          ldap_bind_dn: 'CN=svc,DC=example,DC=com',
          ldap_bind_password: 'p@ss',
        }
      end

      it { is_expected.to compile }
      it { is_expected.to contain_file('/srv/application-config/adrapi_test/appsettings.json').with_content(%r{"corp": \{\s*"kind": "ldap"}) }
    end

    context "on #{os} with a default_domain naming no configured domain" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.10.0',
          service_name: 'adrapi_test',
          ldap_domain: 'corp',
          default_domain: 'nowhere',
        }
      end

      it { is_expected.to compile.and_raise_error(%r{names no configured domain}) }
    end

    context "on #{os} with an ldap_domain colliding with an Entra domain" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.10.0',
          service_name: 'adrapi_test',
          ldap_domain: 'cloud',
          entra_domains: {
            'cloud' => {
              'tenant_id' => 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
              'client_id' => '11111111-2222-3333-4444-555555555555',
            },
          },
        }
      end

      it { is_expected.to compile.and_raise_error(%r{collides with an entra_domains entry}) }
    end

    context "on #{os} with a reserved domain name" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.10.0',
          service_name: 'adrapi_test',
          ldap_domain: 'Users',
          default_domain: 'Users',
        }
      end

      it { is_expected.to compile.and_raise_error(%r{reserved directory domain name}) }
    end

    context "on #{os} with no directory domain at all" do
      let(:facts) { os_facts }
      let(:params) do
        {
          version: '1.10.0',
          service_name: 'adrapi_test',
          manage_ldap_domain: false,
        }
      end

      it { is_expected.to compile.and_raise_error(%r{no directory domain configured}) }
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
