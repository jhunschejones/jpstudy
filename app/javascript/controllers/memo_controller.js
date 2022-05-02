import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "content", "saveButton" ]

  initialize() {
    this.initialContent = this.contentTarget.innerText.trim();
    this.contentTarget.onkeydown = this.autoSave.bind(this);
  }

  autoSave() {
    // clear previous auto-save attempt when user enters more content
    clearTimeout(this.timeout);

    const currentContent = this.contentTarget.innerText.trim();
    if (currentContent != this.initialContent) {
      // start timeout for auto save
      this.timeout = setTimeout(() => {
        // execute auto-save after timeout
        this.saveButtonTarget.click();
      }, 10000);
    }
  }
}
