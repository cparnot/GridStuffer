GridStuffer version 0.2.0

Created by Charles Parnot, 2005.
Copyright Charles Parnot 2005 . All rights reserved.

Contact:
charles.parnot@gmail.com

Read more on the web:
http://cmgm.stanford.edu/~cparnot/xgrid-stanford
http://cmgm.stanford.edu/~cparnot/xgrid-stanford/html/goodies/
http://cmgm.stanford.edu/~cparnot/xgrid-stanford/html/goodies/GridStuffer-details.html


----------
Change Log
----------

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