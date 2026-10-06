import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "container"]

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now().toString())
    this.containerTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-nested-form-row]")

    if (row.dataset.newRecord === "true") {
      row.remove()
    } else {
      row.hidden = true
      row.querySelector("input[name$='[_destroy]']").value = "1"
    }
  }
}
