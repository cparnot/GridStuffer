# Using the Sparkle framework

* See also http://sparkle.andymatuschak.org/wiki/Documentation/Basics
* Link = add framework to the main target
* Create a new Copy Files build phase to copy it in Frameworks subdir
* Instantiate SUUpdater in MainMenu.nib in Interface Builder
* Create a “Check for updates...” menu item in the application menu and connect it to checkForUpdates: in SUUpdater
* Enter the appcast’s URL in Info.plist:

		<key>SUFeedURL</key>
		<string>http://www.yourdomain.com/app/example.xml</string>
		
* Make an appcast:

		<?xml version="1.0" encoding="utf-8"?> 
		<rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sparkle="http:// 
		www.andymatuschak.org/xml-namespaces/sparkle"> 
			<channel> 
				<title>GridStuffer Changelog</title> 
				<link>http://cmgm.stanford.edu/~cparnot/xgrid-stanford/html/goodies/GridStuffer-changelog.txt</link> 
				<description>Description of the latest version of GridStuffer</description>
				<language>en</language> 
				<item>
					<title>Version 0.4.5</title> 
					<description>http://cmgm.stanford.edu/~cparnot/xgrid-stanford/html/goodies/GridStuffer-changelog.txt</description> 
					<pubDate>Fri, 17 August 2007 9:00:00 +0000</pubDate>
					<enclosure
						sparkle:version="0.4.5"
						url="http://cmgm.stanford.edu/~cparnot/xgrid-stanford/downloads/GridStuffer-[v0.4.5].dmg"
						type="application/octet-stream"/>
				</item> 
			</channel> 
		</rss>

* Make a corresponding changelog document, identical to the README.txt file, available at 

		http://cmgm.stanford.edu/~cparnot/xgrid-stanford/html/goodies/GridStuffer-changelog.txt
		
