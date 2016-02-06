# Earned Value Management (EVM) Calculation Plugin

[![Rate at redmine.org](http://img.shields.io/badge/rate%20at-redmine.org-blue.svg?style=flat)](http://www.redmine.org/plugins/redmine_issue_evm)

This plugin provides the function of calculating evm of projects . EVM can help you to track your project progress and its status and to forecast the future performance of the project.


#### Main features
*	Calculate EVM
*	Chart with EVM (PV,EV,AC)
*	Forecast project end date
*	Set the baseline
*	Display unfinished issues

#### Additional options
* Explanation of EVM
* Chart with Project Performance (SPI,CPI,CR)
* Select past baseline
* Change the calculating basic date
* Change the level of the forecast


## How to calculate EVM
The below are used for EVM.

* start date
*	due date
*	estimated time (If you set it as 0, you will not get PV, CV)
*	spent time

If you input these into your project, it can help you to calculate both a single issue’s EVM and whole project’s one.
PV: Dividing estimated time by the days (from start date to due date) to get daily workload
EV: After issues are closed, you can get EV.

#### Example
(1) Create an issue with:

*	start date:  2015/08/01
*	due date:  2015/08/03
*	estimated time: 24 hours

At that time, only PV is calculated. As you have not closed the issue yet, EV equals 0.
PV: Dividing estimated time: 24hours by 3 days (from start date to due date)

| EVM | 8/1 | 8/2 | 8/3 |
| --- | --- | --- | --- |
| PV  | 8   | 16  | 24  |
| EV  | 0   | 0   | 0   |
| AC  | 0   | 0   | 0   |

(2) Input your spent time.

8/1: 10.0hours  8/2: 6.0hours 8/3: 8.0hours

| EVM | 8/1 | 8/2 | 8/3 |
| --- | --- | --- | --- |
| PV  | 8   | 16  | 24  |
| EV  | 0   | 0   | 0   |
| AC  | 10  | 16  | 24  |

(3) After finishing the issue, close it on 8/3. EV will be calculated on 8/3.

| EVM | 8/1 | 8/2 | 8/3 |
| --- | --- | --- | --- |
| PV  | 8   | 16  | 24  |
| EV  | 0   | 0   | 24  |
| AC  | 10  | 16  | 24  |

Based on these data, EVM and chart are created.

## Chart
3 types of charts can be displayed.

#### Main chart
Show PV,EV,AC with baseline.Display unclosed issues according to the baseline.

#### Performance chart
Show SPI,CPI,CR of the days involved with PV,EV,AC

#### Version chart
Show PV,EV,AC of every version in the issue

## Baseline
If you set baseline, you can know easily how project divergence is and whether new task (issues) can be added by chart. In other words, you can see whether your estimated daily workload is over or not by chart.
PV is based on your baseline. In addition, you can set calculation without baseline by options.

## Compatibility
Redmine 3.1 and above

## Current Version
3.5.7

## Installation
#### Getting plugin source
case of zip file.

* Download zip-file
* Create a folder named redmine_issue_evm under [redmine_root]/plugins/
* Extract zip file in redmine_issue_evm

Case of git clone.
```
git clone git://github.com/momibun926/redmine_issue_evm [redmine_root]/plugins/redmine_issue_evm
```
#### Migration and restart

* Input the below command to migration
```
rake redmine:plugins:migrate NAME=redmine_issue_evm RAILS_ENV=production
```
* restart redmine

## UnInstall
```
rake redmine:plugins:migrate NAME=redmine_issue_evm VERSION=0
```

# Screen shots
#### Overview
![evm sample screenshot](./images/screenshot01.png "overview")

#### Baseline setting
History
![evm sample screenshot](./images/screenshot02.png "History")

New baseline
![evm sample screenshot](./images/screenshot03.png "New baseline")

#### Plugin Setting
![evm sample screenshot](./images/screenshot04.png "plugin　setting")

# Contributing
1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request

#### Translators
Wen Wen, Shen.
