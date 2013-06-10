[![Build Status](https://travis-ci.org/jnraine/munkiserver.png?branch=master)](https://travis-ci.org/jnraine/munkiserver) [![Coverage Status](https://coveralls.io/repos/jnraine/munkiserver/badge.png)](https://coveralls.io/r/jnraine/munkiserver)


Munkiserver is a Ruby on Rails web application for managing your munki clients. Clients are in a 1-1 relationship with the server  (i.e. each client has their own manifest), making it easy to specify one off installs. However, you can still group clients together using computer groups and apply software bundles to them, thus achieving the same level of functionality as regular manifests in vanilla munki. All configurations (ex: pkginfo, manifests, bundles, etc…) are stored in a backend relationsl database; there is no flat repo. This adds some complexity however, all management is done through the web application:

* Adding/removing computer clients
* Uploading/editing packages
* Editing manifests
* Assigning user/group permissions
* Viewing which packages have updates (uses www.macupdate.com to check)
* Viewing warranty information
* The list goes on…

For installation instructions and documentation, see the wiki: https://github.com/jnraine/munkiserver/wiki
