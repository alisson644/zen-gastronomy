import { Controller } from "@hotwired/stimulus"

// Mostra a prévia da foto escolhida e exibe o botão "Salvar foto".
export default class extends Controller {
  static targets = ["preview", "save"]

  preview(event) {
    const file = event.target.files[0]
    if (!file) {
      this.saveTarget.hidden = true
      return
    }

    if (this.objectUrl) URL.revokeObjectURL(this.objectUrl)
    this.objectUrl = URL.createObjectURL(file)
    this.previewTarget.src = this.objectUrl
    this.saveTarget.hidden = false
  }

  disconnect() {
    if (this.objectUrl) URL.revokeObjectURL(this.objectUrl)
  }
}
