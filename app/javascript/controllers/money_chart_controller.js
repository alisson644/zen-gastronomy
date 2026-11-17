import Chartjs from "@stimulus-components/chartjs"

// Gráfico Chart.js com valores em reais (R$ 1.234,56) nos eixos e tooltips,
// grade discreta e barras finas com a ponta arredondada.
const brl = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" })
const brlCompact = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL", notation: "compact", maximumFractionDigits: 1 })

const TEXT_SECONDARY = "#52514e"
const GRID = "#e7e5e4"

function isObject(value) {
  return value && typeof value === "object" && !Array.isArray(value)
}

function deepMerge(target, source) {
  const out = { ...target }
  for (const [key, value] of Object.entries(source || {})) {
    out[key] = isObject(value) && isObject(out[key]) ? deepMerge(out[key], value) : value
  }
  return out
}

export default class extends Chartjs {
  get chartOptions() {
    return deepMerge(this.defaultOptions, this.optionsValue)
  }

  get defaultOptions() {
    const horizontal = this.optionsValue?.indexAxis === "y"
    const valueAxis = horizontal ? "x" : "y"
    const categoryAxis = horizontal ? "y" : "x"
    const multiSeries = (this.dataValue?.datasets || []).length > 1

    return {
      responsive: true,
      maintainAspectRatio: false,
      interaction: { mode: "index", intersect: false, axis: categoryAxis },
      datasets: { bar: { borderRadius: 4, borderSkipped: "start", maxBarThickness: 28, categoryPercentage: 0.7, barPercentage: 0.85 } },
      scales: {
        [valueAxis]: {
          beginAtZero: true,
          border: { display: false },
          grid: { color: GRID },
          ticks: { color: TEXT_SECONDARY, maxTicksLimit: 5, callback: (value) => brlCompact.format(value) },
        },
        [categoryAxis]: {
          border: { color: GRID },
          grid: { display: false },
          ticks: { color: TEXT_SECONDARY, autoSkip: !horizontal },
        },
      },
      plugins: {
        legend: {
          display: multiSeries,
          position: "top",
          align: "start",
          labels: { color: TEXT_SECONDARY, usePointStyle: true, pointStyle: "rectRounded", boxWidth: 10, boxHeight: 10 },
        },
        tooltip: {
          callbacks: {
            label: (ctx) => {
              const value = horizontal ? ctx.parsed.x : ctx.parsed.y
              return multiSeries ? `${ctx.dataset.label}: ${brl.format(value)}` : brl.format(value)
            },
          },
        },
      },
    }
  }
}
