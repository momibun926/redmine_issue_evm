# redmine_issue_evm User Guide

This guide explains how to use the EVM plugin (redmine_issue_evm 7.0.2, for Redmine 7.0 or later). For installation, see the [README](../../README.md).

[日本語](../ja/index.md)

## Where to start

| If you want to... | Read |
| --- | --- |
| Just start using it | [Getting started with the minimum setup](quick-start.md) |
| Understand the EVM values and charts | [Reading EVM](evm-basics.md) |
| Use baselines or project reports | [Going further](advanced.md) |
| Use the EVM values from Excel or other services (REST API) | [Going further](advanced.md#7-rest-api-use-the-evm-values-from-excel-and-other-services) |
| Look up what each screen does | [Feature reference](features.md) |
| Fix wrong values or a screen that does not show | [FAQ and troubleshooting](faq.md) |

## What the plugin does (overview)

From the **start date, due date and estimated time** of issues and the **spent time** logged on them, the plugin calculates Earned Value Management (EVM) values and shows them as tables and charts.

- EVM and ES (Earned Schedule) of the whole project, including its subprojects
- Breakdowns by version, assignee, parent issue and tracker
- Baselines: record the plan at a point in time and compare it with later changes
- Project reports that record the EVM values with your comments
- An EVM summary on the project overview page

There are many features, but **the minimum setup in "Getting started" is enough at first**. Add baselines and reports when you need them.
