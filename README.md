# Introduction

This module is a proof of concept implementation of Docker and Virtualenv
support for the OpenStack puppet-designate module.  Where reasonable there is
symmetry between the two methods of installing the software such that it's
generally possible to switch between the two by only changing the environment
specific configuration.

For example, in our environment we use the following block to add support for
virtualenv or docker support:

    class { "::designate_ext::${packaging}":
      config_files => $config_files,
    }
    include "::designate_ext::${packaging}::api"
    include "::designate_ext::${packaging}::central"
    include "::designate_ext::${packaging}::sink"

In the example above, the `packaging` variable is a parameter passed into the
class and would be either `virtualenv` or `docker`.  Both the virtualenv and
docker environments are configured via Hiera.

For both docker and virtualenv support, you should include the corresponding
class for each service you wish to configure as shown above.

## Common configuration
For both docker and virtualenv support, you will want to disable packaging
installation.  You can do this by adding the following to your Hiera config:

    designate::package_ensure: absent
    designate::api::package_ensure: absent
    designate::central::package_ensure: absent
    designate::sink::package_ensure: absent

The designate_ext module contains example configuration files for the Juno
version of Designate that are used with both virtualenv and docker based
installations.  These configuration files can be overridden by passing in a new
config_files parameter to either class.  Note that the example `designate.conf`
config file is only used if the file does not already exist and will be copied
in place before any `designate_config` resources are applied.  On subsequent
runs the `designate.conf` config file will not be replaced.

## Virtualenv: designate_ext::virtualenv

The virtualenv class will copy in place upstart scripts.  This allows the
existing puppet-designate service configuration and dependency trees to
function the same as when using packages.

This example shows one active virtualenv being configured and the previous
version being ensured absent to remove it.  It's possible to have multiple
virtualenvs provisioned and switch by moving the `venv_active: true` configure
from one block to another.

    designate_ext::virtualenv::virtualenvs:
      designate-2014.2-13-g99db2f6.6:
        venv_active: true
        venv_prefix: 2014.2-13-g99db2f6.6
        venv_requirements: 'puppet:///modules/cirrus/designate/2014.2-13-g99db2f6.5-requirements.txt'
        venv_extra_args: >
          --no-index --use-wheel
          -f http://%{hiera("blobmirror")}/python-mirrors/designate-2014.2-13-g99db2f6.5-2015-06-30T14:20:59-938b640.wheels/
      designate-2014.2-13-g99db2f6.5:
        venv_prefix: 2014.2-13-g99db2f6.5
        ensure: absent

## Docker: designate_ext::docker

The docker class will create init script wrappers using the puppet-docker
module, but turn off service management via puppet-docker.  This allows the
existing puppet-designate service configuration and dependency trees to
function the same as when using packages.

This example shows two docker images being configured to be pulled locally,
with the first of the two being active.

    designate_ext::docker::active_image_name: blobmaster:5000/cirrus/designate
    designate_ext::docker::active_image_tag: 2014.2-13-g99db2f6.11.2027fed
    designate_ext::docker::images:
      2014.2-13-g99db2f6.11.2027fed:
        image: blobmaster:5000/cirrus/designate
        image_tag: 2014.2-13-g99db2f6.11.2027fed
      2014.2-13-g99db2f6.10.a4e912:
        image: blobmaster:5000/cirrus/designate
        image_tag: 2014.2-13-g99db2f6.10.a4e912

