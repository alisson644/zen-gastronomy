import { Controller } from "@hotwired/stimulus"

// Linhas de um has_many aninhado (accepts_nested_attributes_for).
// - add: copia o <template> trocando NEW_RECORD por um índice único
// - remove: linhas já salvas são marcadas com _destroy=1 e escondidas; novas são apagadas
export default class extends Controller {
  static targets = ["container", "template", "row"]

  add(event) {
    event?.preventDefault()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, `${Date.now()}${Math.floor(Math.random() * 1000)}`)
    this.containerTarget.insertAdjacentHTML("beforeend", html)
    this.containerTarget.lastElementChild?.querySelector("select, input:not([type=hidden])")?.focus()
  }

  remove(event) {
    event?.preventDefault()
    const row = event.target.closest("[data-nested-fields-target='row']")
    if (!row) return

    const destroy = row.querySelector("input[name$='[_destroy]']")
    const persisted = row.querySelector("input[name$='[id]']")
    if (destroy && persisted) {
      destroy.value = "1"
      row.hidden = true
      row.querySelectorAll("[required]").forEach((el) => (el.required = false))
    } else {
      row.remove()
    }
  }
}
