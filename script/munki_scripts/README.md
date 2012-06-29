## Munki Scripts

This directory will contain a good starting point for Munki preflight/postflight scripts to be downloaded to the client.  There will be some work in the future on having some (or all) of these scripts to be downloaded directly from MunkiServer and to provide a scripting framework to communicate back and forth from the MunkiServer framework. Details to come.

For now, copy both of these files to your /usr/local/munki directory and remove the .rb file extension so they will be executed before and after each munki client run.
Alternatively, _make_ can be used to automatically build a pkg or dmg from these files.
