redmine_issue_evm
=================

Earned value management using the ticket of redmine.
Calculating the EVM values using start-date, due-date, and estimated hours of the issue.

* PV : Split each day the estimated-hours.
* EV : Use the estimated-hours. Added to the closed date of issue.
* AC : Use timeentries.

Installation
=================

Use zip file

1. Download zip-file
2. cd {redmine_root}/plugins/; mkdir redmine_issue_evm
3. Extract files to {redmine_root}/plugins/redmine_issue_evm/
4. rake redmine:plugins:migrate NAME=redmine_issue_evm RAILS_ENV=production

Use git clone

    git clone git://github.com/momibun926/redmine_issue_evm {redmine_root}/plugins/redmine_issue_evm

Future
=================

1. View chart of EVM.
2. Setting baseline.
