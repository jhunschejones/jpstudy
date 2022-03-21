import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "checkIcon", "copyIcon" ]
  static values = { copy: String };

  copy(event) {
    event.preventDefault();
    event.stopImmediatePropagation();

    navigator.clipboard.writeText(this.copyValue);
    this.copyIconTarget.classList.add("hidden");
    this.checkIconTarget.classList.remove("hidden");
    setTimeout(() => {
      this.copyIconTarget.classList.remove("hidden");
      this.checkIconTarget.classList.add("hidden");
    }, 2000);
  }
}
