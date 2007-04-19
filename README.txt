GridStuffer version 0.4.4

Created by Charles Parnot.
Copyright Charles Parnot 2005, 2006, 2007. All rights reserved.

Contact by email:
charles•parnot
at
gmail•com

Read more on the web:
http://cmgm.stanford.edu/~cparnot/xgrid-stanford
http://cmgm.stanford.edu/~cparnot/xgrid-stanford/html/goodies/goodies.html
http://cmgm.stanford.edu/~cparnot/xgrid-stanford/html/goodies/GridStuffer-details.html


----------
Change Log
----------

version 0.4.4
(April 2007)

* Fixed a bug in the parser of the input file, that would consider that all parameters starting with a dash were a GridStuffer parameter, and would thus gobble up the command created by the user if it contained parameters with this format.


version 0.4.3
(March 2007)

* Updated to version 0.4.3 version of GridEZ.framework


version 0.4.2
(March 2007)

* Updated to version 0.4.2 version of GridEZ.framework
* Skipped version 0.4.1 to match GridEZ numbering


version 0.4.0
(February 2007)

* All the Xgrid core functionality moved to GridEZ.framework, including the scheduling part of MetaJobs
* Improved MetaJob scheduling implemented in GridEZ:
	* Simplified options
	* More dynamic submission process
	* Reduced risk of overloading a grid with submission
	* Submission to multiple grids in parallel
* Improved connection process and syncing to controllers, as implemented in GridEZ.framework
* Improved Controllers window, as implemented in GridEZ.framework
* New Xgrid Panel, implemented in GridEZ.framework
* Keychain support, as implemented in GridEZ.framework


version 0.2.4.1
* Autosave persistent store every minute instead of only doing it when quitting
* Remove some superflous messages to the console, leftover from caveman debugging
* Fixed a nasty memory leak, where the data of all the job results would never get realease. Really bad!! (big thanks to Espen for his patience in helping to crush that bug)


version 0.2.2.1

* Forgot to make the store compatible with version 0.2.0
* From now on, versions will be considered compatible within a subversion (e.g. 0.2.x are all compatible but not with 0.3.x, etc...)


version 0.2.2

* The DLog function was still defined, and its arguments evaluated, even though the function itself was empty in Deployement release; this caused at least one reported crash, probably because of large file sizes that used up all the memory


version 0.2.1

* Bug fix: path with the ~ were considered absolute paths when used in the command or argument strings, when they should have been considered relative and should not have been used as is if they corresponded to an existing file on the client. Now, these paths are properly modified and the corresponding files are uploaded to the agents when needed.


version 0.2

* use the SQLLite format for the persistent store
* Fixed deletion of jobs (problem: if not found on the xgrid, a job could be deleted from another program... or maybe not loaded yet) --> using some NSTimers
* the -si flag (stdin) is included in the inputFiles
* same thing with stdout, stderr and output files: now really honor -so and -se and -out
* allow the user to cancel the connection while trying to connect to a server
* bug fix: could not remove server from the GUI and the store
* when a task fail, save results in a special 'failures folder'
* use a hierachical structure for the results, so that one does not get 1000000 folders in one folder, but intermediray folders, e.g. '1-100'
* bug fix: the number of commands per job was one more that set in the GUI and metajob attribute
* cleaner GUI:
	* use the toolbar
	* add metajob status
	* fix metajob progress bar
	* add xgrid job table view
	* add metatask table view
	* the word 'MetaJob' is used consistently in the GUI


version 0.1.1

* first semi-public version
* uses xml format for the persistent store