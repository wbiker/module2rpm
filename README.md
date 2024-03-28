NAME
====

App::Module2Rpm

SYNOPSIS
========

    # Download the source of a Raku module, write the spec file and upload them to OBS.
    module2rpm --module=Module::Name

    # Download the source, write the spec file and upload them to OBS for each line in a file.
    module2rpm --file=filePath

    # Creates the spec and tar file with the content of the current working directory.
    module2rpm .

DESCRIPTION
===========

Please, note: This is still not a 1.0 release. Modules with certain dependencies might fail.

This program downloads the source of a given Raku module, writes the spec file with the module
metadata and uploaded them to Open Build Service (OBS).
There are two commandline parameter:

  * `--module=Module::Name` Looks for the metadata of the given name to find the
   source download url and metadata.

  * `--file=FilePath` Handles each line in the file as either module name or metadata
  download url.

  * `.` Creates spec and tar archive file with the content of the current working directory

AUTHOR
======

wbiker <wbiker@gmx.at>
