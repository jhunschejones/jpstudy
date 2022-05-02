import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "form", "content" ]

  initialize() {
    this.previousContent = this.contentTarget.innerHTML;
    const trixEditor = this.formTarget.querySelector("trix-editor");
    trixEditor.addEventListener("trix-change", this.autoSave.bind(this));
  }

  autoSave() {
    // clear previous auto-save attempt when user enters more content
    clearTimeout(this.timeout);

    const currentContent = this.contentTarget.innerHTML;
    if (currentContent != this.previousContent) {
      // start timeout for auto save
      this.timeout = setTimeout(() => {
        // execute auto-save after timeout
        fetch(this.formTarget.action, {
          method: this.formTarget.method,
          body: new FormData(this.formTarget),
          headers: { Accept: "application/json" }
        }).then((response) => {
          if (response && response.ok) {
            // update our pointer to the current state
            this.previousContent = currentContent;
            return;
          }
          // say something if the form was unable to be submitted
          console.warn("autoSave() failed");
        })
      }, 5000);
    }
  }
}
