## Munki Scripts

This directory contains a good starting point for Munki preflight/postflight scripts to be downloaded/installed on each Munki client. Both of these files (postflight.rb and preflight.rb) should be copied to `/usr/local/munki` on each client.  Be sure to remove the `.rb` file extension so they will be executed before and after each munki client run. The scripts should also be RWX for the owner and should be owned by root.

Alternatively, _make_ can be used to automatically build a pkg or dmg from these files.
