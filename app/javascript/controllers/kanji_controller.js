import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "character" ]

  copy() {
    navigator.clipboard.writeText(this.characterTarget.innerText);
  }
}
