import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { with: String };
  static targets = [ "button" ]

  disableButton() {
    const form = this.element.closest("form");

    // If the form is invalid, don't continue
    if (!form.checkValidity()) {
      return;
    }

    if (this.buttonTarget.nodeName == "INPUT") {
      this.buttonTarget.value = this.withValue;
    } else {
      this.buttonTarget.innerHTML = this.withValue;
    }
    this.buttonTarget.disabled = true;

    // The form submission halts here unless we manually re-send an event
    // https://discuss.hotwired.dev/t/triggering-turbo-frame-with-js/1622/46
    form.dispatchEvent(new CustomEvent("submit", { bubbles: true }));
  }
}
