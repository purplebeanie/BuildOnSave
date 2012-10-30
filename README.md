BuildOnSave
===========

An plugin for Coda 2 that allows you to run Ant scripts for projects automatically on save.  Configurable per project.


##Installation##

1) Open the project in Xcode.  

2) Build

3) Copy the resulting BuildOnSave.codaplugin to your ~/Library/Application Support/Coda 2/Plug-Ins directory.

4) Run Code

##How to Use##

The first time you launch Coda 2 after installing the plugin two files will be created in:

~/Library/Application Support/com.purplebeanie.buildonsave/

* settings.xml - contains the settings for Ant.  By default this assumes the ant is installed in /usr/local/ant/bin/ant, but if ant is installed somewhere else change this file to suit.
* sites.xml - contains a list of projects for which build on save is enabled.

To add additional projects to the sites.xml file either open the sites.xml file and edit manually.  Alternatively you can use the interface.  To add a site:

1. open the project in Coda 2
2. open the plugin menu
3. select the build on save menu option
4. check the Enable for project check box
5. click OK

BuildOnSave assumes a valid Ant build.xml is found in the top level project directory.  It will run ant, passing in the build.xml.

##How to Remove##

Uninstallation is as easy as opening your:

~/Library/Application Support/Coda 2/Plugin-ins directory and deleting the bundle.  You will also need to remove the ~/Library/Application Support/com.purplebeanie.buildonsave directory manually.
