# Earned Value Management (EVM) Calculation Plugin

[![Rate at redmine.org](http://img.shields.io/badge/rate%20at-redmine.org-blue.svg?style=flat)](http://www.redmine.org/plugins/redmine_issue_evm)

This plugin provides the function of calculating evm of projects . EVM can help you to track your project progress and its status and to forecast the future performance of the project.

## Current Version
6.0.1

## Compatibility
Redmine 5.0.0 and above

> *Notification*
>
> The redmine3.4.x compatible version in branch "redmine3-4-3".
> https://github.com/momibun926/redmine_issue_evm/tree/redmine3-4-3
>
> The redmine4.x.x compatible version in branch "redmine4.0".
> https://github.com/momibun926/redmine_issue_evm/tree/redmine4.0

# Main features
## Calculate EVM with chart
  * All projects with ES
  * Each version
  * Each asssignee (Shown estimated hours each days on chart)
  * Each parent issues
  * Some Tarckers
  * Calculating EV based on daily done ratio
  * Daily EAC
## Project reporting based on EVM
  * Project overview can be recorded with EVM values
  * List, query, and edit historical summaries
## Project metrics
  * Duration
  * Satus
  * Days until due date
  * Amount of calculation issues
  * Variance at baseline and show issue list
  * Amount of issue. (version, assignee, tracker)
  * Chart of EVM(PV,EV,AC), Forecast is invalid when project is finished.
## Common setting
  * Basic time of day
  * Calculation method of ETC
  * Forcast chart, Performance chart, Threthold value, incomplete issues
## Create baselines, and view history
  * Create baseline
  * View past created baseline

# How to calculate EVM
The below are used for EVM.

* start date
* due date(If empty, effective of version)
* estimated time (If you set it as 0, you will not get PV, CV)
* spent time

If you input these into your project, it can help you to calculate both a single issue’s EVM and whole project’s one.

* PV: Dividing estimated time by the days (from start date to due date(or effective date of version )) to get daily workload
* EV: After issues are closed, you can get EV.　When the progress rate is set, it is calculated by estimated time. (progress rate on the day when the progress is set.)
* AC: Total work hours of PV issues.

**Example**

(1) Create an issue with:

* start date:  2015/08/01
* due date:  2015/08/03
* estimated time: 24 hours

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

## Baseline
If you set baseline, you can know easily how project divergence is and whether new task (issues) can be added by chart. In other words, you can see whether your estimated daily workload is over or not by chart.
PV is based on your baseline. In addition, you can set calculation without baseline by options.

## View options
* Change the calculating basic date
* Using baseline
* Explanation of EVM

## About workig days
1. Excluding weekends and holidays
2. If it is only weekends or holidays, make it a working day
3. Use holidays gem -> Regional settings are set in the common setting page(common setting link in contextial)

Example)

In Japan, May 3, May 4, May 5 are holidays

* Including weekends and holidays

|Start date          |Due date            |Estimated time |Working day|PV per day|
|--------------------|--------------------|---------------|-----------|----------|
|May 1, 2017 (Monday)|May 8, 2017 (Monday)|12 hours       |3 days     |4 hours   |

* Including only a few weekends and holidays

|Start date          |Due date            |Estimated time |Working day|PV per day|
|--------------------|--------------------|---------------|-----------|----------|
|May 1, 2017 (Monday)|May 7, 2017 (Sunday)|10 hours       |2 days     |5 hours   |

* Only weekends and holidays

|Start date          |Due date            |Estimated time |Working day|PV per day|
|--------------------|--------------------|---------------|-----------|----------|
|May 3, 2017 (Wed)   |May 7, 2017 (Sunday)|20 hours       |5 days     |4 hours   |

# Chart
Chart.js is used to display charts, and Chart.bundle.min.js(Ver2) used in Redmine 4.2 is included with this plugin.
I will make it compatible with Ver3 someday.

**Main Chart**.
Displays the cumulative PV, EV, and AC values from the issue being calculated in a time series. If a baseline has been set, the baseline is also displayed.

**Performance Chart**
Calculates and displays SPI, CPI, and CR only on days when PV, EV, and AC are calculated. If project members frequently close the ISSUE and enter work hours, the accuracy of measuring and predicting overall project performance will be improved.

**Chart by Version**.
If your project is utilizing versions, this is a very useful chart. You can select any version in your project to view the chart.

**Chart by Person**.
Very useful if you have many members in your project. You can see the performance of each member of the team, which is not possible if you only look at the project as a whole.

**Chart by parent issue**.
This chart is for those who are managing tasks with a hierarchical structure of issuess.

**Chart by Tracker**
For those who manage trackers in a subdivided manner and do not want to include trackers in EVM calculations, you can select only the trackers you need and display the chart.

# Installation
(1) Getting plugin source

**case of zip file.**

* Download zip-file
* Create a folder named redmine_issue_evm under [redmine_root]/plugins/
* Extract zip file in redmine_issue_evm

**Case of git clone.**

```
git clone https://github.com/momibun926/redmine_issue_evm [redmine_root]/plugins/redmine_issue_evm
```

(2) bundle install

```
bundle install
```

(3) Migration. At the command line type

```
rake redmine:plugins:migrate NAME=redmine_issue_evm RAILS_ENV=production
```

(4) Restart your Redmine web servers (e.g. mongrel, thin, mod_rails).

(5) Login and configure the plugin (see Permissions section, Administration->plugin)

# UnInstall
```
rake redmine:plugins:migrate NAME=redmine_issue_evm VERSION=0
```

# Screen shots
**Overview-EVM**
![evm sample screenshot](./images/screenshot_main1.png "overview")

**Overview-ES**
![evm sample screenshot](./images/screenshot_main2.png "overview")

**Overview-EVM Chart**
![evm sample screenshot](./images/screenshot_main3.png "overview")

**Overview-EVM Performance chart**
![evm sample screenshot](./images/screenshot_main4.png "overview")

**Overview-EVM Incomplete issue**
![evm sample screenshot](./images/screenshot_main5.png "overview")

**Assignees**
![evm sample screenshot](./images/screenshot_assignee.png "assgnees")

**Prent issues**
![evm sample screenshot](./images/screenshot_parent_issue.png "assgnees")

**Trackers**
![evm sample screenshot](./images/screenshot_tracker.png "assgnees")

**Create baseline**
![evm sample screenshot](./images/screenshot_new_baseline.png "New baseline")

**Baseline History**
![evm sample screenshot](./images/screenshot_history_baseline.png "History")

**Plugin Setting**
![evm sample screenshot](./images/screenshot_common_setting.png "plugin　setting")

# Contributing
1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request

# My Environment
* Redmine version                5.0.0.stable.21553
* Ruby version                   3.1.2-p20 (2022-04-12) [x86_64-linux]
* Rails version                  6.1.5.1
* Environment                    production
* Database adapter               PostgreSQL
* Mailer queue                   ActiveJob::QueueAdapters::AsyncAdapter
* Mailer delivery                smtp

#### Translators
I appreciate your cooperation, Wen Wen, Shen.
