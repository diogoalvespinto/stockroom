import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.buttonTargets.forEach((button) => (button.hidden = true))
  }

  submit() {
    this.element.requestSubmit()
  }
}
