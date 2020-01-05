Features
========

* ``omir``: create a partial or complete local OpenBSD mirror, including firmware files

* ``site``: build and add a configurable ``site.tgz`` to the mirror

* ``site/autoinstall``: create ``install.conf`` response files based on profiles
  and initialize a directory layout for PXE booting

* ``oink``: create a hacked miniroot for autoinstall purposes (``amd64`` only)


Limitations / TODO
==================

- pretty much *amd64*-only

  - ``omir``: arch hardcoded in rsync filter list (``etc/omir.list.skel``)
  - ``site``: should be arch-independent
  - ``site/autoinstall``: mostly arch-independent, has some *amd64* tweaks
  - ``oink``: *amd64* only

- the same ``site.tgz`` will be used for all releases and architectures


Setup
=====

After cloning this repo, review ``etc/omir.env``
and add your customizations to ``etc/omir.env.local``.

Run ``make -C ./etc`` afterwards, this has to repeated whenever
the configuration changes (be it on your behalf or due to git pull).

For building ``site.tgz`` or ``autoinstall`` configuration,
run ``make -C ./etc/site init`` and then review
the configuration files in that directory.

Additionally, for ``autoinstall`` configuration,
create one or more profiles in ``./etc/site/profiles``,
see ``./etc/site/examples/profiles`` for examples.


Mirror
======

Run ``./bin/omir-update`` to sync,
which will fetch release files and packages as well as firmware files
for releases configured via ``OMIR_REL``.

To fetch a specific release not necessarily listed in ``OMIR_REL``, run:

.. code:: shell


   $ ./bin/omir-update 6.x


Site Tarball
============

Run ``make -C site/``, which will build the ``site.tgz`` file
and publish it to all known releases and architectures.


autoinstall
===========

**UNDOCUMENTED SO FAR**: autoinstall configuration

Run ``make -C site/autoinstall``,
which will generate ``<MIRROR_PXE_OPENBSD>/<rel>/<arch>/<profile>/install.conf`` files
for all profiles found in ``etc/site/profiles``.

To create ``bsd.rd`` and ``pxeboot`` symlinks in addition to the response files,
run ``make -C site/autoinstall setup`` instead.


oink
====

**UNDOCUMENTED SO FAR**, but here are a few pointers:

* ``bin/oink-build`` will compile the ramdisk
* place *hook* files in ``share/oink/hooks`` to replace the default built-in hooks
* hooks (include the default ones) may pick up files from ``share/oink/files``
  - for example, ``auto_install.conf`` would be added to the ramdisk by the default ``inject`` hook
* the default ``inject`` hook applies some ugly shell code injections

The build process needs to be run as ``root``,
it tampers with files in ``/usr/src`` and ``/usr/obj``,
and at some point the ramdisk makefile does a ``su build ...``.
Could possibly be circumvented via ``mk.conf(5)``.

Setup recommendations:

* use a dedicated machine/vm for building the ramdisk,
  allocate about 3G of RAM and as much cores as you are comfortable with

* use *mfs* for build directories,
  this makes cleaning up trivial (just unmount)
  while also avoiding disk writes:

  Create ``/skel/obj`` as empty directory with proper permissions/ownership:

  .. code:: shell

     # mkdir -p -- /skel/obj
     # chmod -- 0770 /skel/obj
     # chown -- build:wobj /skel/obj

  Add relevant fstab entries:

  .. code:: text

     swap /usr/obj mfs rw,-s=250m,-P=/skel/obj 0 0
     swap /usr/src mfs rw,-s=2000m 0 0

* run ``oink-build`` as root,
  keep in mind that granting doas for ``oink-build`` to a user
  will practically allow that user to run any command
  if that user is also in control of the script
