import { Controller } from "@hotwired/stimulus"

// Cadastro em passos: mostra um passo por vez e só avança quando os campos do passo atual são válidos.
export default class extends Controller {
  static targets = ["step", "indicator"]

  connect() {
    this.show(0)
  }

  next() {
    if (this.firstInvalidField(this.stepTargets[this.current])) {
      this.stepTargets[this.current].querySelectorAll("input").forEach((field) => field.reportValidity())
      return
    }
    this.show(this.current + 1)
  }

  back() {
    this.show(this.current - 1)
  }

  // Ao enviar, volta para o passo com campo inválido (o navegador não mostra o aviso em campo escondido).
  submit(event) {
    const index = this.stepTargets.findIndex((step) => this.firstInvalidField(step))
    if (index === -1) return

    event.preventDefault()
    this.show(index)
    this.firstInvalidField(this.stepTargets[index]).reportValidity()
  }

  show(index) {
    this.current = Math.max(0, Math.min(index, this.stepTargets.length - 1))

    this.stepTargets.forEach((step, i) => { step.hidden = i !== this.current })
    this.indicatorTargets.forEach((indicator, i) => {
      indicator.toggleAttribute("data-current", i <= this.current)
    })

    this.stepTargets[this.current].querySelector("input:not([type=file])")?.focus()
  }

  firstInvalidField(step) {
    return [...step.querySelectorAll("input, select, textarea")].find((field) => !field.checkValidity())
  }
}
