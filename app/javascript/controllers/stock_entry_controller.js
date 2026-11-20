import { Controller } from "@hotwired/stimulus"

// Formulário de entrada de estoque:
// - mostra o vencimento só quando a forma de pagamento é boleto (e o torna obrigatório)
// - calcula o total de cada item e da entrada
// - ao escolher um produto, sugere o custo médio e a categoria do financeiro dele
export default class extends Controller {
  static targets = ["paymentMethod", "dueOn", "dueOnInput", "item", "quantity", "unitCost", "itemTotal", "total", "subcategory"]

  connect() {
    this.togglePayment()
    this.recalculate()
  }

  itemTargetConnected() {
    this.recalculate()
  }

  itemTargetDisconnected() {
    this.recalculate()
  }

  togglePayment() {
    if (!this.hasPaymentMethodTarget) return

    const boleto = this.paymentMethodTarget.value === "boleto"
    this.dueOnTarget.hidden = !boleto
    this.dueOnInputTarget.required = boleto
    this.dueOnInputTarget.disabled = !boleto
  }

  productChanged(event) {
    const option = event.target.selectedOptions[0]
    const row = event.target.closest("[data-stock-entry-target='item']")
    const cost = row?.querySelector("[data-stock-entry-target='unitCost']")
    if (cost && !cost.value && option?.dataset.cost && option.dataset.cost !== "0,00") cost.value = option.dataset.cost

    if (this.hasSubcategoryTarget && !this.subcategoryTarget.value && option?.dataset.subcategory) {
      this.subcategoryTarget.value = option.dataset.subcategory
    }
    this.recalculate()
  }

  recalculate() {
    // Espera o nested-fields remover a linha antes de somar.
    setTimeout(() => {
      let sum = 0
      this.itemTargets.forEach((row) => {
        if (row.hidden) return
        const quantity = this.parse(row.querySelector("[data-stock-entry-target='quantity']")?.value)
        const unitCost = this.parse(row.querySelector("[data-stock-entry-target='unitCost']")?.value)
        const total = Math.round(quantity * unitCost * 100) / 100
        sum += total
        const cell = row.querySelector("[data-stock-entry-target='itemTotal']")
        if (cell) cell.textContent = total ? this.money(total) : ""
      })
      if (this.hasTotalTarget) this.totalTarget.textContent = this.money(sum)
    })
  }

  // "1.234,56" -> 1234.56 ; "2.5" -> 2.5
  parse(value) {
    if (!value) return 0
    const normalized = value.includes(",") ? value.replace(/\./g, "").replace(",", ".") : value
    const number = parseFloat(normalized)
    return Number.isFinite(number) ? number : 0
  }

  money(value) {
    return value.toLocaleString("pt-BR", { style: "currency", currency: "BRL" })
  }
}
