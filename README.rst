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


Requirements
============

Hardware:

* about 60 GiB of disk space for mirroring a single release for *amd64*


Dependencies:

* git for cloning this repo

* Perl 5

* BSD make (``bmake`` in Debian)

* POSIX-ish shell (+ ``local``)

* coreutils such as ``cp, mkdir, touch, ...``

* for ``omir``:

  * fully-featured ``rsync``, ``openrsync`` will not work

  * cron for updating the mirror automatically

  * HTTP server for hosting the mirror

* for ``site``:

  * tar, preferably the BSD variant (set ``GNU_TAR=1`` otherwise)

* for ``site/autoinstall``:

  * nothing specifically,
    but usually a PXE server environment (DHCP / TFTP)

* for ``oink``:

  * operating system must be OpenBSD


Overview
========

Directory Layout
----------------

**Scripts** meant to be run directly can be found in ``bin/``.
These are just symlinks to ``omir-run``,
which sets up the runtime environment, reads the main configuration
and then calls the actual script, which lives in ``share/scripts``.

Scripts reflecting on the effective configuration are built-in,
namely ``omir-env`` and ``omir-mkenv``.

**Helper scripts** are in ``share/libexec``.

``share/shlib`` contains common **shell code functions**.

**Configuration files** reside in ``etc`` or a subdirectory thereof.
Unless otherwise stated, their format is plain ``<name>=<value>``:

* ``<name>=<value>``: each line consists a variable name and its value, separated by an equality sign

* values containing space characters must be quoted using either single or double quotes (``'<value>'``, ``"<value>"``)

* quoted values will not be unescaped and may therefore not include their enclosing quoting character

  Do not rely on the no-unescaping behavior, it may change in future.

* multiline values are not supported

* no variable expansion will occur, values are taken literally (``$FOO`` is ``$FOO``, not the value of ``FOO``)

* comment lines begin with a hash key ``#`` and will be ignored

* empty lines will be ignored, too

Having a directory named ``obj`` in a configuration directory below ``etc`` will screw things up.

The main configuration file is ``etc/omir.env`` (may be renamed in future).
Keep *your* modifications in ``<config_file>.local`` (e.g. ``etc/omir.env.local``).

Some features have their own directories:

* ``site``:

  * ``etc/site``: configuration

  * ``site``: directory for building the *site* tarball

  * ``site/rootfs``: skeleton for the *site* tarball

* ``site/autoinstall``:

  * ``etc/site``: configuration

  * ``etc/site/profiles``: ``install.conf`` profiles configuration

  * ``site/autoinstall``: build directory

  * ``site/autoinstall/src``: ``install.conf`` generator code

* ``oink``:

  * ``share/oink/hooks``: ramdisk modification scripts

  * ``share/oink/files``: additional files for building the ramdisk such as scripts, kernel config, ...



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

Create the mirror directory ``MIRROR_ROOT`` (default: ``/data/mirror``) first,
and grant the mirror user write access to it.

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
