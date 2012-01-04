# Welcome to NewsClassifier

NewsClassifier is a web application for analyzing potentially large quantities of electronic documents, i.e. web pages or news feeds. NewsClassifier provides a framework for automatically retrieving news articles from RSS feeds, extracting relevant text from messy websites and archive them for later analyses. You can use NewsClassifier as a frontend for manual and automatic (using keywords or regular expressions) coding. It supports unlimited users, news sources and categories. You can run automatic reliability tests and export all results as standard CSV files.

## Installation

NewsClassifier is a Rails application, so installation is fairly standard. 

### Requirements

* Ruby 1.9.2 or later (I recommend using RVM)
* Redis/Resque
* MySQL/PostgreSQL/Sqlite

You also need to have Python 2.6+ installed for the BTE tool.

### Setup

Install the necessary bundles, create the db, go:

	$ bundle install
	$ vim config/database.yml
	$ vim config/config.yml
	
	$ rake db:create

## Getting started

You can manage multiple projects with NewsClassifier, each with its own users, sources, documents and categories. The easiest way to set up a project is the quick_create method:

	$ rails console
	irb> Project.quick_create(title, email, subdomain)

Then start the web server and resque via foreman:

	$ foreman start
	
After creating a project and starting the server, you can access it via a subdomain, i.e. http://projectname.localhost.local You might need to update your hosts file for local testing and setup your web server in production.

You can login with the email supplied above and the password you received.

## License

NewsClassifier is Free Software and licensed under the Affero General Public License 3 (AGPL).

### Disclaimer

NewsClassifier was written as part of my PhD thesis, so it has not been widely tested. Please report bugs or fix them and send pull requests.

Thank you.

&copy; 2008-2012 by Michael Scharkow <michael@underused.org>