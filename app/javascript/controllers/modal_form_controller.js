import { Controller } from "@hotwired/stimulus"

// Closes the surrounding <dialog> after a successful Turbo form submission.
// On validation errors the server answers 422, so the dialog stays open.
export default class extends Controller {
  close(event) {
    if (!event.detail.success) return

    this.element.reset()
    this.element.closest("dialog")?.close()
  }
}
