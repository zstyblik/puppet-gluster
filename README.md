Puppet Gluster
==============

This module installs and configures servers to participate in a [Gluster](http://www.gluster.org/) Trusted Storage Pool, create or modify one or more Gluster volumes, and mount Gluster volumes.

Also provided with this module are a number of custom Gluster-related facts.

## Facts ##
* `gluster_binary`: the full pathname of the Gluster CLI command
* `gluster_peer_count`: the number of peers to which this server is connected in the pool.
* `gluster_peer_list`: a comma-separated list of peer hostnames
* `gluster_volume_list`: a comma-separated list of volumes being served by this server
* `gluster_volume_#{vol}_bricks`: a comma-separated list of bricks in each volume being served by this server
* `gluster_volume_#{vol}_options`: a comma-separared list of options enabled on each volume

The `gluster_binary` fact will look for an [external fact](http://docs.puppetlabs.com/guides/custom_facts.html#external-facts) named `gluster_custom_binary`. If this fact is defined, `gluster_binary` will use that value. Otherwise the path will be searched until the gluster command is found.

## Classes ##
### params.pp ###
This class establishes a number of default values used by the other classes.

### repo.pp ###
This class optionally enables the upstream Gluster.org repositories.  Currently, only the yum repo type is implemented.

### install.pp ###
This class handles the installation of the Gluster packages (both server and client). If the upstream Gluster repo is enabled, this class will install packages from there. Otherwise it will attempt to use native OS packages. Currently only RHEL 6 and RHEL 7 provide native Gluster packages.

### client.pp ###
This class installs the Gluster client package. Usually this is the `gluster-fuse` package, but this can be overridden by class paramaters.

### service.pp ###
This class manages the `glusterd` service.

### init.pp ###
This class implements a basic Gluster server.  It exports a `gluster::server` defined type for itself, and then collects any other exporteed `gluster::server` resources for instantiation.

## Defines ##
### gluster::server ###
This defined type creates a Gluster peering relationship.  The name of the type should be the fully-qualified domain name of a peer to which to connect. An optional `pool` parameter permits you to configure different storage pools built from different hosts.

With the exported resource implementation in `init.pp`, the first server to be defined in the pool will find no peers, and therefore not do anything.  The second server to execute this module will collect the first server's exported resource and initiate the `gluster peer probe`, thus creating the storage pool.

Note that the server being probed does not perform any DNS resolution on the server doing the probing. This means that the probed client will report only the IP address of the probing server.  The next time the probed client runs this module, it will execute a `gluster peer probe` against the originally-probing server, thereby updating its list of peers to use the FQDN of the other server.
http://www.gluster.org/pipermail/gluster-users/2013-December/038354.html

### gluster::volume ###
This defined type creates a Gluster volume. You can specify a stripe count, a replica count, the transport type, a list of bricks to use, and an optional set of volume options to enforce.

Note that creating brick filesystems is up to you. May I recommend the [Puppet Labs LVM module](https://forge.puppetlabs.com/puppetlabs/lvm) ?

If the list of volume options active on a volume do not match the list of options passed to this defined type, no action will be taken by default. You must set the `$remove_options` parameter to `true` in order for this defined type to remove options.

Note that adding or removing options does not (currently) restart the volume.

### gluster::volume::option ###
This defined type applies (Gluster options)[https://github.com/gluster/glusterfs/blob/master/doc/admin-guide/en-US/markdown/admin_managing_volumes.md#tuning-options] to a volume.

To remove an option, set the `remove` parameter to `true`.

### gluster::mount ###
This defined type mounts a Gluster volume.  Most of the parameters to this defined type match either the gluster FUSE options or the [Puppet mount](http://docs.puppetlabs.com/references/3.4.stable/type.html#mount) options.