IPLDevEnvironment
=================

Scripts for use in maintenance and organization of the SINAPSE lab

Usage
-----

    creator.sh [-h] [-v] [-t] [-c] [-r] [-d DIR]
      -h       print this message
      -v       verbose
      -t       testing on
      -c       continue previous build
      -r       refresh/redownload source files
      -d DIR   directory to create/continue (default:'/Shared/sinapse/sharedopt/YYYYMMDD')

Examples
--------

    $ bash creator.sh -v
    $ bash creator.sh -c -d /custom/directory
    $ bash creator.sh -c -r
