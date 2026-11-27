// Charts of the EVM plugin, drawn with the Chart.js of Redmine.
//
// Written the same way as Redmine's own charts (for example
// app/javascript/controllers/reports/details_controller.js): a Stimulus
// controller that reads its data from a <template> as JSON and loads
// Chart.js lazily from Redmine's importmap. The markup is made by
// CommonHelper#evm_chart_tag:
//
//   <div data-controller="evm-chart" data-evm-chart-kind-value="project">
//     <template data-evm-chart-target="data">{"labels": [...], "series": {...}, ...}</template>
//     <canvas data-evm-chart-target="canvas"></canvas>
//   </div>
//
// Kinds: "project" (main EVM chart), "basic" (breakdown by version, parent
// issue or tracker), "assignee" (breakdown by assignee) and "performance"
// (SPI, CPI and CR). Labels are dates as "YYYY-MM-DD".
import { Controller } from "@hotwired/stimulus"
import { application } from "controllers/application"

const NO_FILL = "rgba(0, 0, 0, 0)"

// A line of the chart. Options are Chart.js dataset options.
function line(key, label, color, options = {}) {
  return {
    key: key,
    dataset: Object.assign({
      type: "line", label: label, borderColor: color, backgroundColor: color,
      borderWidth: 2, pointRadius: 1, tension: 0, spanGaps: true, fill: false
    }, options)
  }
}

function dashedLine(key, label, color, dash, width) {
  return line(key, label, color, { borderDash: dash, borderWidth: width, pointRadius: 0, backgroundColor: NO_FILL })
}

const PV = line("pv_actual", "PV", "royalblue")
const EV = line("ev", "EV", "forestgreen")
const AC = line("ac", "AC", "darkorange")

// Series of each kind of chart, in the order of the legend.
const SERIES = {
  project: () => [
    PV, EV, AC,
    line("pv_baseline", "Baseline", "navy", { pointRadius: 0 }),
    dashedLine("bac", "BAC", "dodgerblue", [5, 2], 1),
    dashedLine("eac_daily", "Daily EAC", "gold", [2, 2], 1),
    dashedLine("eac", "EAC", "orange", [5, 2], 1),
    dashedLine("ac_forecast", "AC Forecast", "orange", [2, 2], 2),
    dashedLine("ev_forecast", "EV Forecast", "limegreen", [2, 2], 2),
    { key: "pv_daily",
      dataset: { type: "bar", label: "PV Daily", borderColor: "lightskyblue", backgroundColor: "lightskyblue",
                 borderWidth: 1, order: 1 } }
  ],
  basic: () => [PV, EV, AC],
  assignee: (data) => [
    PV, EV, AC,
    line("pv_daily", data.pvDailyLabel, "lightskyblue",
         { borderWidth: 1, pointRadius: 0, stepped: true, spanGaps: false, fill: "origin", order: 1 })
  ],
  performance: () => [
    line("spi", "SPI", "dodgerblue", { pointRadius: 0 }),
    line("cpi", "CPI", "orange", { pointRadius: 0 }),
    line("cr", "CR", "darkred", { pointRadius: 0 })
  ]
}

// "YYYY-MM-DD" as a local date (no time zone shift).
function parseDate(label) {
  const [year, month, day] = label.split("-").map(Number)
  return new Date(year, month - 1, day)
}

function dateFormat(options) {
  const format = new Intl.DateTimeFormat(document.documentElement.lang || undefined, options)
  return (label) => format.format(parseDate(label))
}

// Vertical line of the basis date and horizontal lines (SPI = 1, working
// hours of a day), drawn over the datasets. Replaces chartjs-plugin-annotation.
const guideLines = {
  id: "evmGuideLines",
  afterDatasetsDraw(chart, _args, options) {
    const { ctx, chartArea, scales } = chart
    ctx.save()
    const index = chart.data.labels.indexOf(options.basisDate)
    if (index >= 0) {
      const x = scales.x.getPixelForValue(index)
      drawLine(ctx, x, chartArea.top, x, chartArea.bottom, "darkred", 1)
      drawTag(ctx, options.basisDateLabel, x, chartArea.top)
    }
    for (const guide of options.horizontal || []) {
      const y = scales.y.getPixelForValue(guide.value)
      if (y >= chartArea.top && y <= chartArea.bottom) {
        drawLine(ctx, chartArea.left, y, chartArea.right, y, guide.color, guide.width)
      }
    }
    ctx.restore()
  }
}

function drawLine(ctx, x1, y1, x2, y2, color, width) {
  ctx.beginPath()
  ctx.strokeStyle = color
  ctx.lineWidth = width
  ctx.moveTo(x1, y1)
  ctx.lineTo(x2, y2)
  ctx.stroke()
}

// Label of the basis date at the top of its line: white text on a dark box.
function drawTag(ctx, text, x, top) {
  if (!text) return
  ctx.font = "bold 12px sans-serif"
  const width = ctx.measureText(text).width + 12
  const height = 20
  ctx.fillStyle = "rgba(0, 0, 0, 0.8)"
  ctx.beginPath()
  if (ctx.roundRect) {
    ctx.roundRect(x - width / 2, top, width, height, 6)
  } else {
    ctx.rect(x - width / 2, top, width, height)
  }
  ctx.fill()
  ctx.fillStyle = "white"
  ctx.textAlign = "center"
  ctx.textBaseline = "middle"
  ctx.fillText(text, x, top + height / 2)
}

function horizontalLines(kind, data) {
  if (kind === "performance") return [{ value: 1, color: "gray", width: 2 }]
  if (kind === "assignee") return [{ value: data.workingHours, color: "red", width: 1 }]
  return []
}

// Chart.js configuration of a chart.
function chartConfig(kind, data) {
  const series = data.series || {}
  const tick = dateFormat({ month: "short", day: "numeric" })
  const title = dateFormat({ year: "numeric", month: "short", day: "numeric", weekday: "short" })
  return {
    type: kind === "project" ? "bar" : "line",
    data: {
      labels: data.labels,
      datasets: SERIES[kind](data).map(({ key, dataset }) =>
        Object.assign({}, dataset, { data: series[key] || [] }))
    },
    options: {
      aspectRatio: 4.5,
      interaction: { mode: "nearest", intersect: false },
      scales: {
        x: {
          grid: { display: false },
          ticks: { maxRotation: 0, autoSkipPadding: 24, callback(value) { return tick(this.getLabelForValue(value)) } }
        },
        y: {
          min: kind === "performance" ? undefined : 0,
          border: { display: false }
        }
      },
      plugins: {
        legend: { position: "bottom" },
        tooltip: { callbacks: { title: (items) => title(items[0].label) } },
        evmGuideLines: {
          basisDate: data.basisDate,
          basisDateLabel: data.basisDateLabel,
          horizontal: horizontalLines(kind, data)
        }
      }
    },
    plugins: [guideLines]
  }
}

class EvmChartController extends Controller {
  static targets = ["data", "canvas"]
  static values = { kind: String }

  connect() {
    const data = JSON.parse(this.dataTarget.content.textContent)
    // It is loaded lazily at runtime, as in Redmine's own charts
    import("chart.js").then((chart) => {
      if (this.chart) return
      this.chart = new chart.default(this.canvasTarget, chartConfig(this.kindValue, data))
    })
  }

  disconnect() {
    if (this.chart) this.chart.destroy()
    this.chart = null
  }
}

application.register("evm-chart", EvmChartController)
