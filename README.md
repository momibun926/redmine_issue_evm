redmine_issue_evm
=================

Earned value management using the ticket of redmine.
Calculating the EVM values using start-date, due-date, and estimated hours of the issue.

* PV : Use the estimated-hours, start date, due date.
* EV : Use the estimated-hours. Added to the closed date of issue.
* AC : Use time entries.


Version
=================

3.1


Environment
=================
Bitnami redmine 3.0.0


Installation
=================

Use zip file

1. Download zip-file
2. cd {redmine_root}/plugins/; mkdir redmine_issue_evm
3. Extract files to {redmine_root}/plugins/redmine_issue_evm/
4. rake redmine:plugins:migrate NAME=redmine_issue_evm RAILS_ENV=production

Use git clone

    git clone git://github.com/momibun926/redmine_issue_evm {redmine_root}/plugins/redmine_issue_evm


Screen shots
=================

Overview

![evm sample screenshot](./doc/screenshot01.png "overview")

Performance chart

![evm sample screenshot](./doc/screenshot04.png "overview")

Baseline setting

History
![evm sample screenshot](./doc/screenshot02.png "overview")

New baseline
![evm sample screenshot](./doc/screenshot03.png "overview")


Contributing
=================

1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request
