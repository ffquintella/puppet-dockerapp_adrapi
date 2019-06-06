require 'spec_helper'

describe 'dockerapp_adrapi::seckey' do
  let(:title) { 'sectest' }
  let(:params) do
    {
      key: 'SDFSDFjw3ersdd',
      id: 'abc123',
      authorized_ip: '1.1.1.1',
      claims: ['isAdministrator', 'test'],
      service_name: 'sectest'
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
      it { is_expected.to contain_class('dockerapp_adrapi::seckey::base') }
    end
  end
end
