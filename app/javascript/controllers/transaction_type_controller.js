import { Controller } from "@hotwired/stimulus"

// Adapts the transaction form to the chosen type:
// - entrada: only income categories (optgroup[data-income="true"])
// - saida: only expense categories (optgroup[data-income="false"])
// - transfer: hides the category and shows the destination account
// Disabled fields are not submitted nor validated as required.
export default class extends Controller {
  static targets = ["type", "category", "subcategorySelect", "relatedAccount", "relatedAccountSelect"]

  connect() {
    this.update()
  }

  // The subcategory select is replaced via Turbo Stream when a category/subcategory is created.
  subcategorySelectTargetConnected() {
    this.update()
  }

  // form.reset() fires "reset" before the fields are restored, so wait a tick.
  reset() {
    setTimeout(() => this.update())
  }

  update() {
    if (!this.hasTypeTarget) return

    const type = this.typeTarget.value
    const isTransfer = type === "transfer"

    this.toggle(this.relatedAccountTarget, this.relatedAccountSelectTarget, isTransfer)
    this.relatedAccountSelectTarget.required = isTransfer

    if (this.hasCategoryTarget && this.hasSubcategorySelectTarget) {
      this.toggle(this.categoryTarget, this.subcategorySelectTarget, !isTransfer)
      this.filterCategories(type)
    }
  }

  toggle(wrapper, field, visible) {
    wrapper.hidden = !visible
    field.disabled = !visible
  }

  filterCategories(type) {
    const select = this.subcategorySelectTarget
    const wantIncome = type === "entrada" ? "true" : type === "saida" ? "false" : null

    select.querySelectorAll("optgroup").forEach((group) => {
      const visible = wantIncome === null || group.dataset.income === wantIncome
      group.hidden = !visible
      group.disabled = !visible
    })

    const selected = select.selectedOptions[0]
    if (selected && selected.parentElement.tagName === "OPTGROUP" && selected.parentElement.disabled) {
      select.value = ""
    }
  }
}
