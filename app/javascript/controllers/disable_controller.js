import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    with: String,
    useDirectFormSubmit: Boolean,
  };
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

    // Allow configuration of direct form submission via data-values (for non-turbo workflows)
    if (this.hasUseDirectFormSubmitValue && this.useDirectFormSubmitValue == true) {
      return form.submit();
    }

    // The form submission does not work here when using Turbo unless we
    // manually re-send the event.
    // https://discuss.hotwired.dev/t/triggering-turbo-frame-with-js/1622/46
    form.dispatchEvent(new CustomEvent("submit", { bubbles: true }));
  }
}
