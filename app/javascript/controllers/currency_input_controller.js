import { Controller } from "@hotwired/stimulus"

// Máscara de valor em reais no padrão brasileiro: "1.234,56".
// Aceita apenas dígitos e uma vírgula (o ponto digitado vira vírgula),
// limita a 2 casas decimais e completa com ",00" ao sair do campo.
export default class extends Controller {
  connect() {
    let value = this.element.value.trim()
    if (!value) return
    // Valor vindo do servidor no formato "1234.5" (ponto como separador decimal)
    if (!value.includes(",") && /^\d+\.\d+$/.test(value)) value = Number(value).toFixed(2).replace(".", ",")
    this.element.value = this.complete(this.format(value))
  }

  input(event) {
    const el = this.element
    let caret = el.selectionStart ?? el.value.length

    // Ponto digitado pelo usuário vira vírgula decimal (se ainda não houver uma)
    if (event?.data === "." && el.value[caret - 1] === ".") {
      const before = el.value.slice(0, caret - 1)
      const after = el.value.slice(caret)
      el.value = (before + after).includes(",") ? before + after : `${before},${after}`
      caret = (before + after).includes(",") ? caret - 1 : caret
    }
    // Quantos dígitos/vírgula existem antes do cursor, para reposicioná-lo após formatar
    const significantBefore = el.value.slice(0, caret).replace(/[^\d,]/g, "").length

    el.value = this.format(el.value)

    let pos = 0
    let seen = 0
    while (pos < el.value.length && seen < significantBefore) {
      if (/[\d,]/.test(el.value[pos])) seen++
      pos++
    }
    el.setSelectionRange(pos, pos)
  }

  blur() {
    this.element.value = this.complete(this.element.value)
  }

  format(raw) {
    let value = raw.replace(/\./g, "").replace(/[^\d,]/g, "")
    const commaIndex = value.indexOf(",")
    let integer = commaIndex === -1 ? value : value.slice(0, commaIndex)
    let decimals = commaIndex === -1 ? null : value.slice(commaIndex + 1).replace(/,/g, "").slice(0, 2)

    integer = integer.replace(/^0+(?=\d)/, "")
    if (integer === "" && decimals !== null) integer = "0"
    integer = integer.replace(/\B(?=(\d{3})+(?!\d))/g, ".")

    return decimals === null ? integer : `${integer},${decimals}`
  }

  complete(value) {
    if (!value) return value
    const [integer, decimals = ""] = value.split(",")
    return `${integer || "0"},${decimals.padEnd(2, "0")}`
  }
}
