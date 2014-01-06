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
- added a very messy data management set of scripts

**note** geoipdns was always patched in a hurry, on a need-basis, most of the times *while being flooded* so the code looks dirty but *it proved itself very stable* over the years.
**note** geoipdns dns support was added so I could have a firewall at DNS service level. While being ddosed there was no reason in taking the heat from other countries than the ones proving themselves to be worthy visitors. For example there are no real romanians reading newspapers from saudi arabia.
**note** geoipdns can be used to create a very simple, level-1 CDN implementation. you can route romanian visitors to a romanian server, english visitors to a britpop server and the rest of the world to bangladesh. however, do consider the case of dns caches like google. those are pushing geoipdns to decide on routing a request in a silly way. hence, consider it to be a level-1 CDN implementation and always have a level-2 "double-check" cdn in your web server.

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

edit the scripts/veridns/cfg.pm module and modify the paths as you like (defaults go to /var/db/geoipdns/{...}

the following scripts are used to manage the data (the data will be edited in tinydns-data format):
- gupdate : updates the geoip database and rebuilds the geoip configurations. usage: ./gupdate check=1 configs=all
- gedit: edit the geoip mappings database
- zdelete <zonename> : deletes a zone
- zedit <zonename> : edit a zone from database
- zimport <zonename> <file> : imports a tinydns-formatted file into database
- zlist : lists the zones from database
- znew <zonename> creates a new zone in database
- zdump <zonename>: dumps a zone in tinydns data format from database
- zexport : commits the data to dns servers

### multiuser support ####
the backend management is somehow multiuser-aware through DNS_ADMIN environment variable. each user can host its own geoip configuration and 
edit its own zone files. anyway, I did not really used this part so it should be considered buggy. the default user is 'admin' and I shall consider 
single user environments in the documentation

### geoip database configuration ######
if you don't need geoip database support then you can either:
- ignore it. if a record is not geoip enabled the it's not. the rr defs are looking the same way as for tinydns
- disable it at compile time. remove -DUSE_LOCMAPS flag from conf-cc

geoip databases are configured through xml files, hosted in /var/db/geoipdns/{username}/ipmaps.xml. A xml file looks like this:

    <!-- define the owner of geoip db and the location where the compiled database will be hosted -->
    <ipmaps user="admin" out="/var/db/geoipdns/admin/loc.data">
    <!-- route the requests at dns level to the nearest/fastest
    server. make an exception for an US ip class that should
    go directly to Saudi Arabia server , bypassing the special_webcache.
    another US ip class should go to egypt server.
    -->
        <map mname="saudi_smart_routing">
            <mapit from="SA" to="saudi_server"/>
            <mapit from="EG,AE" to="egypt_server"/>
            <mapit from="US,UK" to="special_webcache"/>
            <exceptions>
            <except from="75.126.241.171/27" to="saudi_server"/>
            <except from="74.86.118.75/27" to="egypt_server"/>
            </exceptions>
        </map>
        <!-- allow access from Saudi Arabia ips only. the rest of the world is blacklisted  -->
        <map mname="saudi_firewall">
            <mapit from="SA" to="access_ok"/>
        </map>
        <map mname="saudi_uk_channel">
            <mapit from="SA" to="saudi"/>
            <mapit from="UK" to="england"/>
        </map>
        <map mname="saudi_pakistan_channel">
            <mapit from="SA" to="saudi"/>
            <mapit from="PK" to="pakistan"/>
        </map>
        <map mname="egypt_usa_channel">
            <mapit from="EG" to="egypt"/>
            <mapit from="US" to="united_states"/>
        </map>
        <map mname="emirates_romania_channel">
            <mapit from="AE" to="emirates"/>
            <mapit from="RO" to="romania"/>
        </map>
    </ipmaps>




