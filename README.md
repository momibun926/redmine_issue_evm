# Earned Value Management (EVM) Calculation Plugin

[![Rate at redmine.org](http://img.shields.io/badge/rate%20at-redmine.org-blue.svg?style=flat)](http://www.redmine.org/plugins/redmine_issue_evm)

This plugin calculates the EVM (Earned Value Management) values of your projects from the start date, due date, estimated time and spent time of the issues, and shows them with charts. EVM helps you to track the progress and status of a project and to forecast its future performance.

For how to use the plugin, what each feature does and the simplest way to run it, see the [User Guide](docs/en/index.md).

# Version and compatibility
* Plugin version: 7.0.2
* Compatible with **Redmine 7.0 and above only**.

This plugin uses the features of Redmine 7 (for example, the SVG icons). It does not work with earlier versions of Redmine.

# Important changes
## Working days (non-working days)
**If you upgrade from an earlier version, check this.**

When "Exclude the non-working days of Redmine and the public holidays (from the holidays gem)" is checked in the common setting, the days of the week that are excluded have changed.

| | Earlier versions | This version |
|---|---|---|
| Days of the week to exclude | Saturday and Sunday (fixed) | "Non-working days" in **Administration > Settings > Issue tracking** of Redmine |
| Public holidays | Holidays of the region from the holidays gem | No change |

* If the non-working days of Redmine are the default (Saturday and Sunday), the results do not change.
* If the non-working days are not Saturday and Sunday, the working days of the PV change, and so do the values such as PV, SPI and the forecast finish date. The same days of the week are non-working days as in the other pages of Redmine, such as the Gantt chart.
* If all seven days are selected as non-working days, no day of the week is excluded, as in Redmine.
* The PV of the baselines is recalculated in the same way, so the change in the non-working days does not cause a variance from the baseline.
* The values recorded in the reports that were created earlier (PV and SV) do not change. They can differ from the reports that you create after the upgrade by the change in the non-working days.

After the upgrade, check the non-working days of Redmine. If they are not Saturday and Sunday, tell your users about this change.

## "View EVM" is for the members of the project only
**If you upgrade from an earlier version, check this.**

The "View EVM" permission has been described as "only the members of the project can use it", but this was not in effect. This version fixes it.

| | Earlier versions | This version |
|---|---|---|
| The "Non member" and "Anonymous" roles | The permission could be given | The permission is not shown in **Administration > Roles and permissions** and cannot be given |
| The roles of the members of the project | The permission can be given | No change |

* If you gave this permission to the "Non member" or "Anonymous" role in an earlier version, the setting stays in the database, and those users can still see the EVM pages until the role is saved again.
* When the role is saved again, the permission is removed. Then the users who are not members of the project, and the users who are not logged in, can no longer see the EVM pages.
* If you showed the EVM of a public project to people who are not its members, add them to the members of the project.

After the upgrade, open the "Non member" and "Anonymous" roles in **Administration > Roles and permissions** and save them again to remove this permission.

# Main features
## Calculate EVM with charts
* All projects (including descendant projects) with ES
* Each version
* Each assignee (shows the estimated hours of each day on the chart)
* Each parent issue
* Some trackers
* Calculating EV based on the daily done ratio
* Daily EAC
* List of the issues excluded from the calculation
* EVM summary on the project overview page

## Project metrics
* Duration
* Status
* Days until the due date
* Number of the issues used for the calculation
* Variance from the baseline and the list of the issues
* Number of issues of each version, assignee and tracker
* Chart of EVM (PV, EV, AC). The forecast is not shown when the project is finished.

## Baselines
* Record the PV of a project at a point in time
* View the details and the history of the baselines

## Project reports based on EVM
* Record the project overview together with the EVM values
* List, show and edit the past reports

## Common setting
* Basis hours of a day, excluding the non-working days of Redmine and the public holidays from the holidays gem (and the region of the holidays)
* Calculation method of ETC
* Forecast chart, performance chart, threshold values and the list of incomplete issues

# Installation
(1) Get the plugin source

**Zip file**

* Download the zip file.
* Create a folder named `redmine_issue_evm` under `[redmine_root]/plugins/`.
* Extract the zip file into that folder.

**git clone**

```
git clone https://github.com/momibun926/redmine_issue_evm [redmine_root]/plugins/redmine_issue_evm
```

(2) Install the gems (from `[redmine_root]`)

```
bundle install
```

(3) Run the migration

```
bundle exec rake redmine:plugins:migrate NAME=redmine_issue_evm RAILS_ENV=production
```

(4) Precompile the assets (the icons and the stylesheet of the plugin)

```
bin/rails assets:precompile RAILS_ENV=production
```

(5) Restart Redmine.

If the icons or the layout of the plugin are not shown correctly, clear the cache of your browser (Ctrl+F5).
Run (4) and restart Redmine again whenever you update the plugin and its stylesheets, scripts or images were changed.

# Uninstallation
```
bundle exec rake redmine:plugins:migrate NAME=redmine_issue_evm VERSION=0 RAILS_ENV=production
```

Then remove the `redmine_issue_evm` folder from `[redmine_root]/plugins/` and restart Redmine.

# Getting started
(1) Set the permissions in Administration > Roles and permissions. The permissions of this plugin are listed in the section "EVM".

(2) Enable the module "EVM" in Settings > Modules of the project.

(3) Click the "EVM" tab of the project. The first time, the common setting page is shown. Save the setting to start using the plugin.

For recommended setting values and the rules for daily use, see [Getting started with the minimum setup](docs/en/quick-start.md).

## Permissions
| Permission | What you can do |
| --- | --- |
| View EVM | Show the EVM tab and its pages (project, versions, assignees, parent issues, trackers, excluded issues and the baseline difference). Only the members of the project can use it. |
| View Baseline | Show the list, the history and the details of the baselines. |
| Edit Baseline | Create, edit and delete the baselines (and show them). |
| Edit Common Setting | Create and edit the common setting of the project. |
| View Project report | List, show, create, edit and delete the project reports. |

## Dates and time zones
* The basis date (status date) is the date of your browser when you open the EVM page for the first time.
* Dates in other pages (for example, the project overview and the activity) follow the time zone of your account. If it is not set, the time zone of the server is used. In that case, the date can be one day behind in the morning, for example in Japan when the server runs in UTC. Please set the time zone in My account.

# How to calculate EVM
The following items of an issue are used.

* start date
* due date (If empty, the effective date of the version)
* estimated time (If you set it to 0, you will not get PV and CV)
* spent time

If you input these into your project, the plugin calculates both the EVM of each issue and the EVM of the whole project. The PV and EV are calculated for each issue, regardless of the parent-child relationship of the issues.

* PV: The estimated time is divided by the number of days (from the start date to the due date, or the effective date of the version) to get the daily workload. The PV is the accumulation of it.
* EV: After an issue is closed, you get the EV on that day. When the done ratio is set, the EV is the estimated time multiplied by the done ratio, on the day when the done ratio is set.
* AC: Total work hours of the issues used for the PV.

**Example**

(1) Create an issue with:

* start date: 2015/08/01
* due date: 2015/08/03
* estimated time: 24 hours

At that time, only PV is calculated. As you have not closed the issue yet, EV equals 0.
PV: dividing the estimated time (24 hours) by 3 days (from the start date to the due date) gives 8 hours per day.

| EVM | 8/1 | 8/2 | 8/3 |
| --- | --- | --- | --- |
| PV  | 8   | 16  | 24  |
| EV  | 0   | 0   | 0   |
| AC  | 0   | 0   | 0   |

(2) Input your spent time.

8/1: 10.0 hours, 8/2: 6.0 hours, 8/3: 8.0 hours

| EVM | 8/1 | 8/2 | 8/3 |
| --- | --- | --- | --- |
| PV  | 8   | 16  | 24  |
| EV  | 0   | 0   | 0   |
| AC  | 10  | 16  | 24  |

(3) After finishing the issue, close it on 8/3. EV is calculated on 8/3.

| EVM | 8/1 | 8/2 | 8/3 |
| --- | --- | --- | --- |
| PV  | 8   | 16  | 24  |
| EV  | 0   | 0   | 24  |
| AC  | 10  | 16  | 24  |

Based on these data, the EVM values and the charts are created.

## Baseline
A baseline records the PV of the project at a point in time. After you set a baseline, you can see in the chart how far the project diverges from it, for example whether new issues were added or the schedule was changed. In other words, you can see whether your estimated daily workload is over or not.
When a baseline is set, the EVM values are calculated based on the baseline. In the view options you can choose to calculate without the baseline. Then all the issues, including the ones added or changed after the baseline was created, are used for the calculation.
You can also look at the baselines created in the past.

## View options
* Change the basis date of the calculation
* Use the baseline or not
* Show the explanation of the EVM values

## About working days
1. The non-working days of Redmine and the public holidays (from the holidays gem) can be excluded from the calculation of PV (set it in the common setting page). The non-working days are "Non-working days" in **Administration > Settings > Issue tracking** of Redmine (Saturday and Sunday by default; the examples below use the default).
2. If the period of an issue consists only of non-working days and holidays, all of the days are working days.
3. Holidays are provided by the holidays gem. Set the region in the common setting page (the "Common setting" link in the contextual menu).

Example)

In Japan, May 3, May 4 and May 5 are holidays.

* The period includes weekends and holidays

|Start date          |Due date            |Estimated time |Working days|PV per day|
|--------------------|--------------------|---------------|------------|----------|
|May 1, 2017 (Monday)|May 8, 2017 (Monday)|12 hours       |3 days      |4 hours   |

* The period includes weekends and holidays (the due date is a weekend)

|Start date          |Due date            |Estimated time |Working days|PV per day|
|--------------------|--------------------|---------------|------------|----------|
|May 1, 2017 (Monday)|May 7, 2017 (Sunday)|10 hours       |2 days      |5 hours   |

* The period consists only of weekends and holidays

|Start date          |Due date            |Estimated time |Working days|PV per day|
|--------------------|--------------------|---------------|------------|----------|
|May 3, 2017 (Wed)   |May 7, 2017 (Sunday)|20 hours       |5 days      |4 hours   |

# Charts
The charts are drawn with the Chart.js that comes with Redmine (v4.5.1 in Redmine 7.0). Chart.js is not included in this plugin.

**Main chart**
Displays the cumulative PV, EV and AC values of the calculated issues in a time series. If a baseline has been set, the baseline is also displayed.

**Performance chart**
Calculates and displays SPI, CPI and CR only on the days when PV, EV and AC are calculated. If the project members frequently close issues and enter work hours, the accuracy of measuring and predicting the performance of the whole project improves.

**Chart by version**
Very useful if your project uses versions. You can select any version of the project to view its chart.

**Chart by assignee**
Very useful if you have many members in your project. You can see the performance of each member, which is not possible if you only look at the whole project.

**Chart by parent issue**
For those who manage tasks with a hierarchical structure of issues.

**Chart by tracker**
For those who manage trackers in a subdivided manner and do not want to include some trackers in the EVM calculation. You can select only the trackers you need and display the chart.

# REST API
The EVM values (the same values as the "EVM" and "ES" tables of the main page) can be read in the same way as Redmine's REST API.

```
GET /projects/<project identifier or id>/evms.json
GET /projects/<project identifier or id>/evms.xml
```

* Turn on "Enable REST web service" in Administration > Settings > API.
* Authentication is the same as Redmine's REST API (the API access key in the `X-Redmine-API-Key` header or the `key` parameter, or basic authentication).
* The "View EVM" permission is needed (project members only).

**Parameters**

|Parameter|Value|Description|
|---|---|---|
|`baseline`|`latest` (default)|Calculate with the latest baseline. When the project has no baseline, it is calculated without one (`baseline` is `null`).|
||`none`|Calculate without a baseline, with the current state of the issues.|
|`basis_date`|`YYYY-MM-DD`|Basis date. Today (in the user's time zone) when it is not given.|

**Example**

```
curl -H "X-Redmine-API-Key: <API access key>" "https://redmine.example.com/projects/myproject/evms.json?baseline=none&basis_date=2026-01-08"
```

```json
{
  "evm": {
    "project": { "id": 7, "name": "EVM scenario" },
    "basis_date": "2026-01-08",
    "baseline": null,
    "working_hours": 8.0,
    "no_data": false,
    "ev_state": "progress",
    "plan_state": "within_duration",
    "finished_date": null,
    "plan_start_date": "2026-01-05",
    "plan_due_date": "2026-01-16",
    "hours": { "bac": 60.0, "complete_ev": 33.3, "pv": 32.0, "ev": 20.0, "ac": 16.0, "sv": -12.0, "cv": 4.0,
               "spi": 0.63, "cpi": 1.25, "cr": 0.79, "etc": 32.0, "eac": 48.0, "vac": 12.0, "tcpi": 0.9 },
    "days": { "bac": 7.5, "complete_ev": 33.3, "pv": 4.0, "ev": 2.5, "ac": 2.0, "sv": -1.5, "cv": 0.5,
              "spi": 0.63, "cpi": 1.25, "cr": 0.79, "etc": 4.0, "eac": 6.0, "vac": 1.5, "tcpi": 0.9 },
    "earned_schedule": { "sac": 12, "es": 2, "at": 4, "tv": -2, "tpi": 0.5, "teac": 24, "tvac": -12 }
  }
}
```

* `baseline`: the baseline used for the calculation (`id`, `subject`, `created_on`), or `null` without a baseline.
* `hours` is in hours, `days` in person-days (divided by `working_hours`, the "Basis hours of day" of the common setting).
* `ev_state`: `no_work` (no finished issues), `progress` or `finished`. `plan_state`: `before_plan`, `within_duration` or `overdue`.
* When the project is finished (`finished_date` is given), `etc`, `eac`, `vac`, `tcpi`, `teac` and `tvac` are `null` ("-" on the page).
* When there are no issues to calculate, `no_data` is `true` and there are no values such as `hours`.
* Errors (status 422, `{"errors": [...]}`): `baseline` other than `latest` or `none`, `basis_date` that is not a date, or no common setting in the project.

# Screenshots
**Overview - EVM**
![evm sample screenshot](./images/screenshot_main1.png "overview")

**Overview - ES**
![evm sample screenshot](./images/screenshot_main2.png "overview")

**Overview - EVM chart**
![evm sample screenshot](./images/screenshot_main3.png "overview")

**Overview - Performance chart**
![evm sample screenshot](./images/screenshot_main4.png "overview")

**Overview - Incomplete issues**
![evm sample screenshot](./images/screenshot_main5.png "overview")

**Assignees**
![evm sample screenshot](./images/screenshot_assignee.png "assignees")

**Parent issues**
![evm sample screenshot](./images/screenshot_parent_issue.png "parent issues")

**Trackers**
![evm sample screenshot](./images/screenshot_tracker.png "trackers")

**Create baseline**
![evm sample screenshot](./images/screenshot_new_baseline.png "New baseline")

**Baseline history**
![evm sample screenshot](./images/screenshot_history_baseline.png "History")

**Common setting**
![evm sample screenshot](./images/screenshot_common_setting.png "common setting")

# Development
## Environment
The plugin is developed and tested with:

* Redmine 7.0.2
* Ruby 4.0.0
* Rails 8.1.3
* PostgreSQL

## Tests
The tests are in `test/`. Run them from `[redmine_root]` (the test database of Redmine must be prepared):

```
bundle exec rake redmine:plugins:test NAME=redmine_issue_evm RAILS_ENV=test
```

## Coding style
The style is checked with RuboCop (RuboCop 1.72 or later, rubocop-rails and rubocop-performance). Run it in the plugin folder. The settings are in `.rubocop.yml`.

```
rubocop
```

## Continuous integration (GitHub Actions)
On every push and pull request to the master and redmine7 branches, GitHub Actions runs RuboCop, the autoload check and the tests (Redmine 7.0.2, Ruby 4.0, PostgreSQL). The settings are in `.github/workflows/tests.yml`. The results are on the "Actions" tab of the repository, where you can also start a run by hand.

## Contributing
1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request

# Languages and translators
English, Japanese, Chinese, Czech, Spanish and Portuguese are supported.
I appreciate your cooperation, Wen Wen, Shen.
