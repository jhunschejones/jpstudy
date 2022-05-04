import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "checkIcon", "copyIcon", "tooltipText" ]
  static values = { copy: String };

  copy(event) {
    event.preventDefault();
    event.stopImmediatePropagation();

    navigator.clipboard.writeText(this.copyValue);
    this.copyIconTarget.classList.add("hidden");
    this.checkIconTarget.classList.remove("hidden");
    this.tooltipTextTarget.classList.toggle("show", true);
    setTimeout(() => {
      this.copyIconTarget.classList.remove("hidden");
      this.checkIconTarget.classList.add("hidden");
      this.tooltipTextTarget.classList.toggle("show", false);
    }, 2000);
  }
}
