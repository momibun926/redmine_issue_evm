# FAQ and troubleshooting

[Back to contents](index.md)

## A page does not show

### There is no EVM tab in the project

Check these three things:

1. "EVM" is enabled in the project's **Settings > Modules**
2. Your role has the **View EVM** permission (**Administration > Roles and permissions**)
3. You are a member of the project (this permission works only for members)

### Opening the EVM tab gives "403"

This happens when the project has no common setting yet and you do not have the **Edit Common Setting** permission: the first time, the EVM tab moves you to the page that creates the common setting. Ask someone with the permission to open the EVM tab once and save the common setting.

### The layout is broken, or the tabs show as radio buttons

The plugin's stylesheet is not loaded. Run the following in the Redmine folder and restart Redmine. You also need this after updating the plugin.

```
bin/rails assets:precompile RAILS_ENV=production
```

If it still looks wrong, clear the browser cache and reload (Ctrl+F5).

### "No data to display" is shown

No issue is in the calculation. Create issues with a start date and a due date (or a target version that has a date).

## A value looks wrong

### An issue I created is not in the calculation

Look at **Exclude issues**. It lists issues with no start date, or with neither a due date nor a target version that has a date.

If the start date or due date field is disabled for the tracker, you cannot enter it at all. Check the standard fields in **Administration > Trackers**.

### AC is less than the real spent time

AC includes **only the time logged on the issues in the calculation**. These are not included:

- Time logged on the project without choosing an issue
- Time logged on issues left out of the calculation (issues without a start date or due date)

### CPI is 0, or ETC is 0

With no spent time logged (AC is 0), CPI is 0 and so is ETC. They are calculated once spent time is logged. When EV is 0, SPI and CPI are 0 as well.

### I set % Done, but EV did not grow

EV is counted **on the day % Done is changed**. If you set % Done when you created the issue, there is no record of the change (journal), so it is not counted as EV. Update % Done after creating the issue, or close the issue: on the day it is closed, the whole estimated time becomes EV.

### BAC is bigger than I expected

Check that you have not entered estimated time on both a parent issue and its children. The plugin calculates each issue on its own, so if the parent also has the total of its children, it is counted twice. We recommend entering estimated time only on child issues.

### Days off and holidays are included in PV

In the **common setting**, check that "Exclude the non-working days of Redmine and the public holidays (from the holidays gem) in duration of days calculation" is checked and that "Regions to get a holiday" is your region.

The days of the week off follow "Non-working days" in Redmine's **Administration > Settings > Issue tracking** (Saturday and Sunday by default), the same days as the Gantt chart. The public holidays are those of the region in the holidays gem.

Note that when an issue's whole period is on non-working days or holidays, all its days are treated as working days.

### Dates are off by one day

Dates on other pages, such as the project overview and activity, follow the time zone in your account. Without one, the server's time zone (often UTC) is used, so in time zones far from UTC the date can be the previous or next day for part of the day. Set your time zone in **My account**.

The status date on the EVM page is the date on your browser (device) when you first open it.

### The overview page and the EVM page show different values

The summary on the overview page is always calculated for **today** with **the latest baseline**. If you changed the status date on the EVM page, or chose another baseline or "Not use", the values differ.

### The values changed after I created a baseline

With a baseline, the project's EVM page is calculated with **the PV of the latest baseline**. Issues added after the baseline are not in PV. To calculate with the current plan, check "Not use" in the options. See [Going further](advanced.md#1-baselines-record-the-plan-and-see-changes) for details.

## Running the plugin

### Which features should I use first?

The [minimum setup](quick-start.md) is enough: enter the start date, due date and estimated time on issues, log spent time, and close issues when they are done. Add baselines and project reports when you want to manage plan changes or need regular reports.

### How big should issues be?

EV is counted on the day an issue is closed (or its % Done is updated). With large issues, EV does not grow until they are finished, so the project looks late. Issues that take one to three days make the chart closer to reality.

### A project report disappeared

When you create a report with the same status date as an existing one, the existing report is replaced. Only one report is kept per status date.

### Are issues of subprojects included?

Yes. The project's EVM includes the issues of all its subprojects.

### I want to calculate with an older baseline

In **Options > Use baseline for EVM value** on the EVM page, choose the baseline and click **Apply**.

### What happens to the EVM data when a project is deleted?

The common setting, baselines and project reports are deleted with it (including those of its subprojects). Archiving a project deletes nothing.

In older versions of the plugin, the EVM data stayed after the project was deleted. To see how many such records are left, run this in the Redmine folder:

```
bundle exec rake redmine_issue_evm:orphans:count RAILS_ENV=production
```

To delete them, run the following. This cannot be undone, so back up the database first.

```
bundle exec rake redmine_issue_evm:orphans:delete RAILS_ENV=production
```
