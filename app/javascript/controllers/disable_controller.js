import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { with: String };
  static targets = [ "button" ]

  disableButton() {
    console.log("here")
    this.buttonTarget.innerHTML = this.withValue;
    this.buttonTarget.disabled = true;
    // The form stops here unless we manually submit it now
    // https://discuss.hotwired.dev/t/triggering-turbo-frame-with-js/1622/46
    this.element.closest("form").dispatchEvent(new CustomEvent("submit", { bubbles: true }));
  }
}
