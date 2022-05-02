import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "saveButton", "form", "content" ]

  initialize() {
    this.previousContent = this.contentTarget.innerHTML;
    const trixEditor = this.formTarget.querySelector("trix-editor");
    trixEditor.addEventListener("trix-change", this.contentChanged.bind(this));
    // start the saved button in a disabled state to indicate no new changes
    this.saveButtonTarget.disabled = true;
  }

  contentChanged() {
    // set the saved button disabled state to indicate whether there were changes made
    this.saveButtonTarget.disabled = !this.contentHasChanged();
    this.autoSave();
  }

  autoSave() {
    // clear previous auto-save attempt when user enters more content
    clearTimeout(this.timeout);

    if (this.contentHasChanged()) {
      // start timeout for auto save
      this.timeout = setTimeout(() => {
        // execute auto-save after timeout
        const contentBeingSaved = this.contentTarget.innerHTML;
        fetch(this.formTarget.action, {
          method: this.formTarget.method,
          body: new FormData(this.formTarget),
          headers: { Accept: "application/json" }
        }).then((response) => {
          if (response && response.ok) {
            // update our pointer to the current state that was just saved
            this.previousContent = contentBeingSaved;
            // reset the saved button disabled state to indicate no new changes
            this.saveButtonTarget.disabled = true;
            return;
          }
          // say something if the form was unable to be submitted
          console.warn("autoSave() failed");
        })
      }, 5000);
    }
  }

  contentHasChanged() {
    return this.contentTarget.innerHTML != this.previousContent;
  }
}
