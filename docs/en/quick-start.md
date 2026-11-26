# Getting started with the minimum setup

This page describes the simplest way to run the plugin: no baselines and no project reports, **just put the plan in your issues, log spent time, and look at the EVM page**. We recommend starting this way and moving on to [Going further](advanced.md) once you are used to it.

[Back to contents](index.md)

## 1. Preparation (done once by an administrator)

### 1-1. Install the plugin

Follow "Installation" in the [README](../../README.md). If you skip `assets:precompile`, the plugin's pages are not styled correctly.

### 1-2. Give the permissions to roles

In **Administration > Roles and permissions**, give the permissions under "EVM" to the roles that should see EVM (for example, Manager and Developer). The minimum setup needs these two:

| Permission | Give it to |
| --- | --- |
| View EVM | everyone who looks at EVM |
| Edit Common Setting | the person who creates the common setting (for example, the project manager) |

"View EVM" works only for members of the project.

### 1-3. Check the Redmine settings

EVM is calculated from standard Redmine fields, so the following must be available:

- In the project's **Settings > Modules**, "Issue tracking" and "Time tracking" are enabled
- For the trackers you use, the standard fields **Start date, Due date and Estimated time** are enabled (check in **Administration > Trackers**)
- In **Administration > Settings > Issue tracking**, under "Parent tasks attributes", Start date / Due date and % Done are set to "Calculated from subtasks" (the Redmine default)

## 2. Enable EVM in the project

1. In the project's **Settings > Modules**, check "EVM" and save.
2. An **EVM** tab appears in the project menu. Click it.
3. The first time, the "Create EVM setting" page opens. For the minimum setup, these values are enough:

| Field | Recommended value | Meaning |
| --- | --- | --- |
| Basis hours of day | `8.0` | Working hours per day, used to convert hours into days |
| Exclude holidays and weekend in duration of days calculation | checked | PV is spread over working days only |
| Regions to get a holiday | your region (for example `us`, `gb`, `jp`) | Where the public holidays come from |
| ETC calculation method | Normal | How the remaining work is estimated. If unsure, choose "Normal" |
| Show forecast line | checked | Shows forecast lines up to completion in the chart |
| Performance | checked | Shows the chart of SPI and CPI over time |
| SPI / CPI / CR threshold | `0.9` | Values at or below this are shown in red (more than 0, up to 0.99) |
| Incomplete Issues | checked | Shows the issues that are past their due date and not finished |

4. Save. The EVM page is shown.

## 3. How to enter issues (rules for every member)

The minimum setup has **only three rules**.

1. **When you create an issue, enter the start date, due date and estimated time**
   - Issues without a start date and a due date are left out of the EVM calculation. (If the due date is empty but the target version has a date, the version's date is used.)
   - Issues with no estimated time are included, but count as 0 hours, so they add nothing to PV and EV.
2. **When you work, log the spent time on that issue**
   - AC adds up only the time logged on the issues in the calculation. Time logged on the project without an issue, or on issues left out of the calculation, is not included.
3. **When you finish, set the issue to a closed status**
   - On the day the issue is closed, its whole estimated time is counted as EV.
   - To show progress along the way, update the % Done. On the day you change it, "estimated time × % Done" is counted as EV.

> **Parent and child issues**: the simplest way is to enter the estimated time only on child issues (the issues at the bottom of the tree) and leave it empty on the parent. The plugin calculates PV for each issue, so if the parent also has the total of its children, the hours are counted twice.

## 4. Reading the page (once a week, just these)

When you open the EVM tab, it shows the values as of today. Look at these four first:

| Where | How to read it |
| --- | --- |
| **SPI** (table on the EVM tab) | Below 1 means behind schedule. Values at or below the threshold are red |
| **CPI** (table on the EVM tab) | Below 1 means the work is taking more time than planned |
| **Metrics > Status** | The overall state, such as "Within the project period" or "Over due date" |
| **Incomplete Issues** tab | Issues that are past their due date and not finished: the place to start looking for the cause of a delay |

Also check **Exclude issues** (a link at the top right of the page) from time to time. Issues with a missing start date or due date show up there.

The upper row of the table is in hours; the lower row is in days (hours divided by "Basis hours of day").

## 5. Example

Three people work for one week (Monday, December 7 to Friday, December 11, 2026).

| Issue | Start date | Due date | Estimated time | PV per day |
| --- | --- | --- | --- | --- |
| A Design | 12/7 | 12/8 | 16 hours | 8 hours |
| B Implementation | 12/9 | 12/11 | 24 hours | 8 hours |
| C Test preparation | 12/7 | 12/11 | 10 hours | 2 hours |

BAC (total estimated time) is 50 hours.

At the end of December 9, the state is:

- A was closed on 12/8. Spent time: 10 hours on 12/7 and 8 hours on 12/8
- C's % Done was updated to 50% on 12/9. Spent time: 2 hours each day from 12/7 to 12/9
- B was started on 12/9 with 4 hours of work. % Done is still 0%

With the status date 12/9, the values are:

| Value | Calculation | Result |
| --- | --- | --- |
| PV | A 16 + B 8 + C 6 | 30 hours |
| EV | A 16 + C 10 × 50% | 21 hours |
| AC | A 18 + B 4 + C 6 | 28 hours |
| SV | EV − PV | −9 hours (behind) |
| CV | EV − AC | −7 hours (over) |
| SPI | EV ÷ PV | 0.70 |
| CPI | EV ÷ AC | 0.75 |
| ETC (Normal) | (BAC − EV) ÷ CPI | about 38.7 hours |
| EAC | AC + ETC | about 66.7 hours |

Both SPI and CPI are at or below the 0.9 threshold, so they are shown in red. Read it as: "We are behind schedule and the work is also taking more time than planned. At this rate the whole project will take about 67 hours."

## What to read next

- More about the values: [Reading EVM](evm-basics.md)
- Recording plan changes, or reporting regularly: [Going further](advanced.md)
- When a value looks wrong: [FAQ and troubleshooting](faq.md)
