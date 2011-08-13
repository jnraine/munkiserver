## munkiserver

munkiserver is the (you guessed it) server-side component to munki, a project developed by Greg Neagle (http://code.google.com/p/munki/).  munki allows large scale manage software deployment on OS X computers in a way that was never possible (well, not for free anyway).  To simplify and extend the functionality of munki, munkiserver offers a web-based GUI that allows a one-to-one modeling for a computer's software.  

### Why you should use munkiserver

1. GUI == a happy admin
munki is an amazing tool for software distribution on OS X, however, managing the server component can be tedious, particularly if you have many administrators or many computers that need different packages.  munkiserver aims to replace text editing with a point-and-click workflow.  No need to manually edit a plist file, or regenerate catalogs after making a change.

2. Macro and micro management
munkiserver prescribes paradigms for macro and micro management.  munkiserver expects you to create a computer object for every single computer, either manually or importing Apple Remote Desktop.  This is handy if you have a user who needs one set of applications and another user who needs a completely different set of applications.  Alternately, if you need to push a piece of software to a group of machines, simply add that package to the computer group.  Have a suite of packages that you're constantly pushing out together?  Group them together in a bundle and assign those to a computer, computer group, or even another bundle.

3. Version Tracking and Updates
For some cases, such as a drag-and-drop application install, munkiserver provides version tracking that notifies you if an application you are managing has an update from macupdate.com.  It even allows you to automagically add that package to your munkiserver with one click.

### Installation

Check out the munkiserver wiki setup doc: http://wiki.github.com/jraine/munkiserver/setup-on-106-server

### First login

A user is created by the bootstrapper with the **username** 'default' and the **password** 'Password1'.  Use this after setting up the server -- don't forget to change the default, or create a new user.

### State of the code

This code is relatively untested and currently relies on a sqlite3 database backend.  I wouldn't recommend putting this into production quite yet.  I do recommend you install it on a server (or workstation, for that matter) and test it on one or two computers.  Munki is a gentle manager and can be added and removed very easily to any computer. That being said, it is being used at a few universities and small companies.  Feel free to report bugs, submit feature requests and suggest future directions.  

A production-ready version of the code is hoping to be released late Fall or Winter.

### Other comments

-	Right now, Munki environments do not mingle.  This means that if a computer is "Production" and a package is "Staging", you cannot assign the package to the computer.
-	All packages start in the staging environment.
-	After adding a computer object, you can download a ManagedInstalls.plist file that contains all the appropriate settings for that particular client.  To do this, click on the "Computers" link and then click "Client Prefs" for the desired computer record.

### Contributing / Help

If you're interested in contributing to the project or would like help getting your server setup, feel free to download the code and start playing with it.  Questions may be directed to our googlegroup mailing list: http://groups.google.com/group/munkiserver-dev.