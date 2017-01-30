# == Class: os_docker::keystone::ssl
#
# This class configures SSL for keystone docker images.
#
# === Parameters
#
# [*ssl_path*] (optional) Path where SSL certs will be installed.
# Default: /etc/keystone/ssl
#
# [*cert*] (optional) Certificate for keystone endpoints. Default: undef
#
# [*key*] (optional) Keyfile for keystone endpoints. Default: undef
#

class os_docker::keystone::ssl(  
  $ssl_path      = hiera('os_docker::keystone::ssl::ssl_path', '/etc/keystone/ssl'),
  $cert          = hiera('os_docker::keystone::ssl::cert', undef),
  $key           = hiera('os_docker::keystone::ssl::key', undef),
)
{
  keystone_config { 'ssl/cert_required': value => false }
  $cert_path = "${ssl_path}/certs"
  $key_path = "${ssl_path}/private"

  if $cert and $key {
    File {
      owner => 'keystone',
      group => 'keystone',
    }

    file { $ssl_path:
      ensure => 'directory',
      mode   => '0755',
    }

    file { $cert_path:
      ensure  => 'directory',
      mode    => '0755',
      require => File[$ssl_path],
    }

    file { $key_path:
      ensure  => 'directory',
      mode    => '0750',
      require => File[$ssl_path],
    }

    file { "${cert_path}/keystone.pem":
      ensure  => 'file',
      content => $cert,
      mode    => '0644',
      require => File[$cert_path],
    }

    file { "${key_path}/keystonekey.pem":
      ensure  => 'file',
      content => $key,
      mode    => '0640',
      require => File[$key_path],
    }
  }
}
