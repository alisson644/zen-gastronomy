import { Controller } from "@hotwired/stimulus"

// Sidebar lateral esquerda.
// - Desktop: alterna entre expandida e recolhida (só ícones); estado salvo no localStorage.
// - Mobile: abre/fecha como gaveta sobre o conteúdo.
const STORAGE_KEY = "sidebar:collapsed"

export default class extends Controller {
  connect() {
    let collapsed = false
    try { collapsed = localStorage.getItem(STORAGE_KEY) === "true" } catch (_) {}
    this.element.toggleAttribute("data-collapsed", collapsed)
    // Só liga as animações depois de aplicar o estado inicial (evita "piscar" ao navegar)
    requestAnimationFrame(() => this.element.setAttribute("data-animate", ""))
  }

  toggle() {
    const collapsed = this.element.toggleAttribute("data-collapsed")
    try { localStorage.setItem(STORAGE_KEY, collapsed) } catch (_) {}
  }

  open() {
    this.element.setAttribute("data-open", "")
  }

  close() {
    this.element.removeAttribute("data-open")
  }
}
