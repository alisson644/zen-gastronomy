import { Controller } from "@hotwired/stimulus"

// Alterna os preços dos planos entre mensal e anual.
export default class extends Controller {
  static targets = ["option", "price"]

  select(event) {
    const period = event.currentTarget.dataset.period

    this.optionTargets.forEach((option) => {
      option.setAttribute("aria-pressed", option.dataset.period === period)
    })
    this.priceTargets.forEach((price) => {
      price.hidden = price.dataset.period !== period
    })
  }
}
