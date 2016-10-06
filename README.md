# Introduction

This module is an implementation of Docker support for the puppet-OpenStack
modules.

## Supported Projects

 * Designate https://github.com/openstack/puppet-designate
 * Glance    https://github.com/openstack/puppet-glance
 * Heat      https://github.com/openstack/puppet-heat
 * Ironic    https://github.com/openstack/puppet-ironic
 * Keystone  https://github.com/openstack/puppet-keystone
 * Neutron   https://github.com/openstack/puppet-neutron
 * Nova      https://github.com/openstack/puppet-nova
 * Swift     https://github.com/openstack/puppet-swift


Using Designate as an example, in our environment we use the following block to
add Docker support to the Designate module:

    class { '::os_docker::designate':
      release_name => 'kilo',
    }
    include ::os_docker::designate::api"
    include ::os_docker::designate::central"
    include ::os_docker::designate::sink"

For docker support, you should include the corresponding class for each service
you wish to configure as shown above.

## Configuration
For docker support, you will want to disable packaging installation.  You can
do this for Designate by adding the following to your Hiera config:

    designate::package_ensure: absent
    designate::api::package_ensure: absent
    designate::central::package_ensure: absent
    designate::sink::package_ensure: absent

The os_docker module contains example configuration files for the Juno, Kilo,
Liberty, Mitaka and Newton versions of each supported project.  These configuration
files can be overridden by passing in a new config_files parameter to either class.
Note that the main config file for each project (`designate.conf`, `heat.conf`,
etc.) is only used if the file does not already exist and will be copied in
place before any `*_config` resources are applied.  On subsequent runs
the main config file will not be replaced unless the release_name parameter is
changed.  If you do not pass in a config_files parameter then example config
files from the release you specify will be used.

The service specific classes (os_docker::<project>::<service>) will create init
script wrappers using the puppet-docker module, but turn off service management
via puppet-docker.  This allows the existing puppet module's service
configuration and dependency trees to function the same as when using packages.

This example shows a Juno designate docker image being configured to be pulled
locally and activated via Hiera.

    os_docker::designate::release_name: juno
    os_docker::designate::active_image_name: blobmaster:5000/cirrus/designate
    os_docker::designate::active_image_tag: 2014.2-13-g99db2f6.11.2027fed

## Neutron Support notes

Some Neutron agents have long lived external processes that provide services
that shouldn't be tied to the lifetime of the agent container.  The L3 agent
has the keepalived process for HA routers, and the DHCP agent has the dnsmasq
process.

In order to separate the lifetime of these processes out from the agents that
spawn them, the containers the agents are started in are given access to the
docker socket.  This allows them to intercept calls to keepalived and dnsmasq
and then start those processes in a separate container.  The DHCP agent and L3
agent containers share the host pid namespace, so they can use the pid files
written by dnsmasq and keepalived to health check them.

Note that L3 agent and DHCP agent containers are already privileged, so they're
effectively running as the root user already.  It's expected that the
additional security implications of allowing them access to the Docker Engine
socket should be minimal.

Examples of the sort of wrappers that can be used inside the container can be
found in the `wrappers/` directory.

## Swift Support notes

The swift service can be configured in a very diverse set of configurations.
Different linux operating systems manage system services in a variety of way.
Rather then depend or try to code around every method used, the puppet-swift
module provides a service resource called the "swiftinit" service provider.
This provider is a custom provider that is a wrapper around the core swift
process management tool called "swift-init".  Swift can start one to many
services of each server type based on more then one configuration file.  The
swiftinit provider simplifies swift service management across platforms.
The os_docker support in this module depends on use of this service provider.

The puppet-swift swiftinit provider will write out init/systemd scripts
that leverage swift-init to provide service start/stop support at boot. This
is different from other services in this os_docker module that use the docker::run
wrapper to create boot time support.

### Swift docker images
A swift docker image should contain the following python elements:
 * swift
 * keystonemiddleware
 * python-swiftclient

### os_docker::swift defines/classes:

 * os_docker::swift
Creates a replacement for /usr/bin/swift-init that is a wrapper around a
container that will run the swift-init service which will then start
whichever service is passed into it.
ex: swift-init object-server.2 start

This will start a container called "object-server.2 start", as well as write
the PID(using host PID space) for this service to /var/run/swift.  Subsequent calls to swift-init
will have access to that PID file and have privilege to terminate a running
swift-init swift service container.

The swift-init os_docker::command uses a custom template.  This template
will run commands other than "status" in a detached container.  This allows
puppet to start the service and disconnect from the container.  The status command
is run in a container with disconnect turned off so that the return code can
be passed back into the puppet-swift swiftinit service provider which relies on it
for service control. This same command wrapper will watch the container and
remove it once it exits.  This hack will be removed once docker 1.13 releases
which will allow using -d and --rm together.

 * os_docker::swift::account
 * os_docker::swift::container
 * os_docker::swift::object

Creates a wrapper command around the account services passed in. These
wrappers can be used to start the services directly in their own container
which can be useful for debug purposes.

Does not yet provide a base configuration file for A/C/O services. This
support will be added once template config file service is converted to ini
provider service in the puppet-swift module.
Ex:

    $account_services = ['auditor','reaper','replicator','server'],
    $container_services = ['auditor','replicator','server','updater'],
    $object_services = ['auditor','server','reconstructor','updater'],
    os_docker::swift::account { $account_services: }
    os_docker::swift::container { $container_services: }
    os_docker::swift::object { $object_services: }

 * os_docker::proxy
The same as the account/container/object classes above but includes support
for providing a proxy-server.conf file.  The proxy portion of puppet-swift
has been converted away from template conifg files to inifile provider configs.

* os_docker::util
Used by the os_docker::swift class along with params.pp to create
wrappers around each swift utility service in a container.
See os_docker::swift::params.pp for a list of utilities.
