# Going further

Once you are used to the [minimum setup](quick-start.md), add the following features as you need them. Each one can be used on its own, so there is no need to start them all at once.

[Back to contents](index.md)

| Feature | Use it when you want to |
| --- | --- |
| [Baselines](#1-baselines-record-the-plan-and-see-changes) | Record plan changes (added issues, later due dates) and compare them |
| [Project reports](#2-project-reports-record-the-status-regularly) | Keep the EVM values and your comments weekly or monthly |
| [Breakdown pages](#3-breakdown-pages-narrow-down-the-cause) | Find which version, assignee or work a delay or overrun comes from |
| [Status date and CSV](#4-status-date-and-csv-export) | See the values at a past date, or work with them in a spreadsheet |

## 1. Baselines (record the plan and see changes)

### What a baseline is

A baseline is **a copy of the start date, due date and estimated time of each issue at the moment it is created**. With a baseline, you can compare with "the original plan" even after issues are added or due dates move.

### Permissions

| Permission | What it allows |
| --- | --- |
| View Baseline | View the list (history) and details of baselines |
| Edit Baseline | Create, edit and delete baselines |

### How to create one

1. Click **Baseline setting** at the top right of the EVM page.
2. On the Baseline History page, click **New Baseline**. BAC, start date and due date show values calculated from the current issues (they cannot be changed).
3. Enter the subject, the basis date of the baseline and a description, then create it.

The basis date of the baseline is a date for your records (for example, the day the plan was approved). It is not used in the EVM calculation.

### When to create one

- Create one **when the plan is fixed** (after the kickoff or plan approval).
- Create a new one **when a major plan change is approved** (added scope, a new release date).
- Putting a date or reason in the subject makes them easy to tell apart in the history (for example, `2026-12-01 initial plan`, `2027-01-15 after adding feature X`).

When you create a new baseline, it becomes "Latest" and the earlier ones become "old". If you delete the latest baseline, the newest remaining one becomes "Latest" again.

### What changes when there is a baseline

- **The project's EVM page is calculated with the PV of the latest baseline** (EV and AC are calculated from the current issues). In other words, it shows how far you are against the original plan.
- **Baseline variance** appears in **Metrics**, showing whether BAC, the due date of the project or the schedule has changed. **Show more details...** opens the lists of new, modified and removed issues.
- A line for the baseline's PV is added to the EVM chart.

To calculate with the current plan, check "Not use" under **Options > Use baseline for EVM value**. You can also choose an older baseline.

> The breakdown pages (versions, assignees, parent issues and trackers) do not use baselines. They are always calculated from the current issues.

## 2. Project reports (record the status regularly)

### What a project report is

A project report records the EVM values at that time (BAC, PV, EV, AC, SV and CV) together with your written comments. The difference from the previous report is also shown, which helps in a weekly meeting to explain "what changed since last week".

The permission needed is **View Project report**.

### How to use it

1. On the project's EVM page, show the status date you want to report (usually today).
2. Click **Project report** at the top right.
3. "Previously reported EVM", "EVM on status date" and "Previously reported EVM differences" are shown. The report details are filled in with the text of the previous report, so edit it and save.
4. Past reports are in **Report list**.

### Things to know

- The values in a report are in **days** (hours divided by "Basis hours of day").
- The report also records the baseline used on the page.
- **If you create a report with the same status date as an existing one, the existing one is replaced** (one report per status date).
- Reports and baselines also appear in Redmine's **Activity** and **Search**.

### A suggested format

If you use the same headings every time, you only need to edit the previous text.

```
h3. Status
SPI 0.85, CPI 0.92. Implementation is still behind.

h3. Cause
Two days lost waiting for the review of feature X.

h3. Action
One more reviewer added. Aim for SPI 0.95 by 12/20.
```

## 3. Breakdown pages (narrow down the cause)

The values for the whole project do not tell you where the delay is. The links at the top right of the EVM page open breakdowns.

| Page | Good for |
| --- | --- |
| Versions | Comparing the progress of each release |
| Assignees | Seeing each member's progress and workload. The chart shows the estimated working hours per day and a line for "Basis hours of day", so you can see where too much is planned |
| Parent issues | Looking at each group, when features or phases are grouped under parent issues |
| Trackers | Looking at each kind of work, such as Feature or Bug. You can also leave out trackers you do not want to include |

They all work the same way: choose items from the list in **Options** (you can choose several) and click **Apply**. The EVM values and a chart are shown for each chosen item.

## 4. Status date and CSV export

- **Status date**: set "Status date" in Options to a past date to see the values as of that day. Useful for retrospectives or for writing a report afterwards. **Clear** returns to today.
- **Explanation**: check "View explanation of EVM value to sidebar" in Options to show what each value means in the sidebar. Handy when looking at the page with members who are new to EVM.
- **CSV**: the **CSV** link below the table on the EVM tab exports the cumulative PV, EV and AC for each date.

## 5. The project overview page

For projects with a common setting, the project's **Overview** page shows an EVM summary as of today (BAC, PV, EV, AC, SV, CV, SPI and CPI). If there is a baseline, the latest one is used. You can check the state of the project without opening the EVM page.

## 6. Reviewing the common setting

You can change the common setting at any time from **Common setting** at the top right of the EVM page (permission: Edit Common Setting).

| Field | When to review it |
| --- | --- |
| Basis hours of day | When the real working hours per day are far from 8 (this changes the values in days and the line on the assignee chart) |
| Holidays and region | When the project follows the holidays of another region |
| ETC calculation method | When the forecast seems too optimistic or too pessimistic (see [Reading EVM](evm-basics.md#3-forecasts)) |
| Thresholds | When too many or too few values are shown in red or orange |
