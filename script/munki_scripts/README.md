## Munki Scripts

This directory contains a good starting point for Munki preflight/postflight scripts to be downloaded/installed on each Munki client. Both of these files (postflight and preflight) should be copied to `/usr/local/munki` on each client.  These files should also be R-X for the owner and should be owned by root:wheel.

Alternatively, _make_ can be used to automatically build a pkg or dmg from these files.

View more documentation on (the wiki)[https://github.com/jnraine/munkiserver/wiki/Munkiserver-preflight-and-postflight].
