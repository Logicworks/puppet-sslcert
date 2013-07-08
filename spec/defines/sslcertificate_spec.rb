require 'spec_helper'

powershell = 'powershell.exe -ExecutionPolicy RemoteSigned'

describe 'sslcertificate', :type => :define do
  describe 'when managing a ssl certificate' do
    let(:title) { 'certificate-testCert' }
    let(:params) { {
        :name       => 'testCert',
        :password   => 'testPass',
        :location   => 'C:\SslCertificates',
        :root_store => 'LocalMachine',
        :store_dir  => 'My',
    } }

    it { should include_class('sslcertificate::param::powershell') }

    it { should contain_exec('Install-SSL-Certificate-testCert').with ({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; \$pfx = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2; \$pfxPass = ConvertTo-SecureString \\\"testPass\\\" -asplaintext -force; \$pfx.import(\\\"C:\\SslCertificates\\testCert.pfx\\\",\$pfxPass,\\\"Exportable,PersistKeySet\\\"); \$store = New-Object System.Security.Cryptography.X509Certificates.X509Store(\\\"My\\\", \\\"LocalMachine\\\"); \$store.open(\\\"MaxAllowed\\\"); \$store.add(\$pfx); \$store.close();\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if(Get-ChildItem cert:\\ -Recurse | Where-Object {\$_.FriendlyName -match \\\"testCert\\\" } | Select-Object -First 1) { exit 1 } else { exit 0 }\"",
    })}
  end
end
