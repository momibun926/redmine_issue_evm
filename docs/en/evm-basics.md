# Reading EVM

EVM (Earned Value Management) compares three values — the plan, the work done and the actual cost — to show delays and cost overruns as numbers. This page explains what the values on the plugin's pages mean and how to read them.

[Back to contents](index.md)

## 1. The three basic values

In this plugin the unit is hours. (The lower row of the tables is in days: hours divided by "Basis hours of day" in the common setting.)

| Value | Name | How the plugin calculates it |
| --- | --- | --- |
| **PV** | Planned Value | The estimated time of each issue, spread evenly over the working days from its start date to its due date, added up to the status date |
| **EV** | Earned Value | The estimated time of the closed issues. When % Done is set, "estimated time × % Done" is counted on the day % Done was changed |
| **AC** | Actual Cost | The total spent time logged on the issues in the calculation |

In short: PV is "how much should be done by now", EV is "how much is actually done", and AC is "how much time it actually took".

## 2. Variances and performance

| Value | Calculation | How to read it |
| --- | --- | --- |
| **BAC** | Total estimated time of all issues | The planned size of the whole project |
| **Complete EV** | EV ÷ BAC | What percentage of the whole is done |
| **SV** | EV − PV | Negative means behind schedule |
| **CV** | EV − AC | Negative means over cost (more spent time than planned) |
| **SPI** | EV ÷ PV | Below 1 means behind. 0.8 means "at 80% of the planned pace" |
| **CPI** | EV ÷ AC | Below 1 means over. 0.8 means "one hour of work produces only 0.8 hours of progress" |
| **CR** | SPI × CPI | Combined schedule and cost performance. 1 or more is good |

SPI, CPI and CR are shown in red when they are at or below the threshold in the common setting, and in orange when they are above the threshold but below 1.

## 3. Forecasts

| Value | Calculation | How to read it |
| --- | --- | --- |
| **ETC** | Estimate of the remaining work (see the table below) | How many more hours it will take |
| **EAC** | AC + ETC | How many hours it will take in total |
| **VAC** | BAC − EAC | Negative means the project is expected to finish over the plan |
| **TCPI** | (BAC − EV) ÷ (BAC − AC) | The performance needed to finish within the remaining estimate. Above 1 means you must work more efficiently than now to stay within the plan |

The ETC method is chosen from three options in the common setting.

| Option | Calculation | Assumption |
| --- | --- | --- |
| Optimistic | BAC − EV | The rest goes as planned |
| Normal | (BAC − EV) ÷ CPI | The rest goes at the same cost performance as so far |
| Pessimistic | (BAC − EV) ÷ CR | The rest goes at the same cost and schedule performance as so far |

When the project is finished, the forecast values are shown as "-".

## 4. ES (Earned Schedule)

SV and SPI are in units of time (effort), so they do not tell you "how many days behind" you are, and near the end of a project SPI tends toward 1 even when the project is late. ES shows the schedule in days instead. It is on the **Earned Schedule** tab next to the EVM tab (the unit is days).

| Value | Meaning |
| --- | --- |
| **SAC** | Planned duration (working days from the start date to the end date) |
| **ES** | The day in the plan on which the current EV should have been reached |
| **AT** | Working days from the start date to the status date (or to the finish date, if finished) |
| **TV** | ES − AT. Negative means behind by that many days |
| **TPI** | ES ÷ AT. Below 1 means behind |
| **TEAC** | SAC ÷ TPI. Total duration if the current pace continues |
| **TVAC** | SAC − TEAC. Negative means the project is expected to finish that many days late |

## 5. Reading the charts

### EVM Charts

Shows the cumulative PV, EV and AC by date.

- If the **EV line is below the PV line**, you are behind schedule. If the **AC line is above the EV line**, you are over cost.
- When a baseline is used, the baseline's PV is also shown. The gap to the current PV is the change in the plan (added issues, changed due dates).
- When "Show forecast line" is enabled in the common setting, forecast lines up to completion are shown too.

### Performance Charts

Shows SPI, CPI and CR over time. Only the days on which PV, EV and AC are calculated are used, so the more often members close issues and log spent time, the more accurate the values are.

## 6. Common misreadings

- **Without logged spent time, CPI is not calculated** (when AC is 0, CPI is shown as 0). When CPI is 0, ETC is also 0, and EAC equals AC.
- **EV hardly grows until issues are closed.** If you do not use % Done, EV jumps on the day a large issue is closed. Splitting issues into pieces of one to three days makes the chart closer to reality.
- **Issues without estimated time add nothing to PV or EV.** If only spent time is logged on them, only AC grows and CPI goes down.
