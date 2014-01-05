about geoipdns
==============
geoipdns started as a set of patches written to add functionality and improve speed of djbdns/tinydns.

what has been modified over the years (I think I wrote it back in 2007 and continued to modify it until last year) is:
- added maxmind geoip support. I needed an easy way to filter ips at country level and implement now and then a very simple CDN system.
- improved the hashing function (using sfhash gives better results)
- the geoip database was integrated reusing cdb
- added epoll/inotify support to get rid of database open/close thundering herd
- added tcp support. 
- added multiprocessing support. geoipdns can be spawned many times (think one process per cpu) to increase the processing power. xtables is needed to properly route the requests but see more information below


installation notes
=================
some hints on building and installing geoipdns are required in order to make your life easier.

compilation 
-----------
- by default, I assume to find inotify.h in sys/. If this isn't your case and your inotify support 
comes with inotify-tools package, then you have to remove -DSYS_INOTIFY from conf-cc

using geoipdns
=============

software dependencies
----------------------
the following software packages must be installed as prerequisites for data management:
- postgresql
- perl
- required perl modules
        Data::Dumper
        Data::Validate::Domain
        Data::Validate::IP
        DBI
        Digest::MD5
        File::Basename
        IO::Uncompress::Unzip
        JSON
        JSON::XS
        File::Basename
        LWP::Simple
        Number::Interval
        Term::ReadLine
        Text::CSV_XS
        Tie::Handle::CSV
        XML::Simple


setting up the backend
----------------------

geoipdns uses postgresql to host the zones. this is pretty much hardcoded inside the management scripts and i'm not planning changing anything from this point of view.
postgresql is used only for data management. the data is exported in cdb format into the live service. the backend shouldn't | mustn't stay on the public dns servers.
to set it up, run the following commands after postgresql is installed:

    createuser -U postgres -DPRS geoipdns
    createdb -U postgres -O geoipdns geoipdns
    #geoipdns-schema.sql is located in the scripts directory
    psql -U geoipdns geoipdns < geoipdns-schema.sql



