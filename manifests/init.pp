# Author::    Paul Stack (mailto:pstack@opentable.com)
# Copyright:: Copyright (c) 2013 OpenTable Inc
# License::   MIT

# == Define: sslcertificate
#
# This defined type will install SSL Certs on windows
#
# === Requirements/Dependencies
#
# Currently reequires the puppetlabs/stdlib module on the Puppet Forge in
# order to validate much of the the provided configuration.
#
# === Parameters
#
# [*password*]
# The password for the given certifcate
#
# [*location*]
# The location to store intermediate certificates
#
# [*thumbprint*]
# The thumbprint used to verify the certifcate
#
# [*store_dir*]
# The certifcate store where the certifcate will be installed to
#
# [*root_store*]
# The store location for the given certifcation store. Either LocalMachine or CurrentUser
#
# === Examples
#
# To install a certificate in the My directory of the LocalMachine root store:
#
#  sslcertificate { "Install-PFX-Certificate" :
#    name       => 'mycert.pfx',
#    password   => 'password123',
#    location   => 'C:\',
#    thumbprint => '07E5C1AF7F5223CB975CC29B5455642F5570798B'
#  }
#
# To install a certifcate in an alterntative direcotory:
#
#  sslcertificate { "Install-Intermediate-Certificate" :
#    name       => 'go_daddy_intermediate.p7b',
#    location   => 'C:\',
#    store_dir  => 'CA',
#    root_store => 'LocalMachine',
#    thumbprint => '07E5C1AF7F5223CB975CC29B5455642F5570798B'
#  }
#
define sslcertificate(
  $password,
  $location,
  $thumbprint,
  $script_dir = 'c:/temp',
  $root_store = 'LocalMachine',
  $store_dir = 'My'
) {
  validate_re($name, '^(.)+$',"Must pass name to ${module_name}[${title}]")
  validate_re($location, '^(.)+$',"Must pass location to ${module_name}[${title}]")
  validate_re($thumbprint, '^(.)+$', "Must pass a certificate thumbprint to ${module_name}[${title}]")

  ensure_resource('file', $script_dir, { ensure => directory })

  case $operatingsystemrelease {
    '2012', '2012 R2': {
      file { "inspect-${name}-certificate.ps1" :
        ensure             => present,
        path               => "${script_dir}/inspect-${name}.ps1",
        content            => template('sslcertificate/inspect.ps1.2012.erb'),
        require            => File[$script_dir],
        source_permissions => ignore
      }

      exec { "Install-${name}-SSLCert":
        provider  => powershell,
        command   => "${script_dir}/import-${name}.ps1",
        onlyif    => "if (Test-Path Cert:\\${root_store}\\${store_dir}\\${thumbprint}) { exit 1 } else { exit 0 }",
        logoutput => true,
        require   => [ File["inspect-${name}-certificate.ps1"], File["import-${name}-certificate.ps1"] ],
      }
    }
    '2008', '2008 R2': {
      file { "inspect-${name}-certificate.ps1" :
        ensure             => present,
        path               => "${script_dir}/inspect-${name}.ps1",
        content            => template('sslcertificate/inspect.ps1.erb'),
        require            => File[$script_dir],
        source_permissions => ignore
      }

      file { "import-${name}-certificate.ps1" :
        ensure             => present,
        path               => "${script_dir}/import-${name}.ps1",
        content            => template('sslcertificate/import.ps1.erb'),
        require            => File[$script_dir],
        source_permissions => ignore
      }

      exec { "Install-${name}-SSLCert":
        provider  => powershell,
        command   => "${script_dir}/import-${name}.ps1",
        onlyif    => "if (& ${script_dir}/inspect-${name}.ps1 ) { exit 0 } else { exit 1 }",
        logoutput => true,
        require   => [ File["inspect-${name}-certificate.ps1"], File["import-${name}-certificate.ps1"] ],
      }
    }
    default: {
      fail("Unsupported Windows Version ${::operatingsystemrelease}")
    }
  }
}
