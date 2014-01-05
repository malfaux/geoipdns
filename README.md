compilation notes
-----------------
- by default, I assume to find inotify.h in sys/. If this isn't your case and your inotify support 
comes with inotify-tools package, then you have to remove -DSYS_INOTIFY from conf-cc

