xtables RAWNAT is used to do load balancing in order to properly support geoipdns multiprocessing.

the RAWNAT extension needs to be patched. the patch was written for xtables-addons-1.46 but it also 
works for xtables-addons-1.47.1. the patch won't apply properly for newer xtables-addons version. 
if one needs so, please commit a clean patch and I'll happily accept it. I'm using 1.47.1 on my systems and I have no interest to update for
newer xtables-addons versions.

p.s. the xtables source tree is already patched!
