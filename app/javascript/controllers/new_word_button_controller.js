import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Remove filters before loading the form when adding a new word from the words list page
  disableFilters() {
    if (location.search.length > 0) {
      Turbo.visit("/words");
      setTimeout(() => {
        document
          .querySelector("#new-word-form .new-word")
          .dispatchEvent(new CustomEvent("click", { bubbles: true }));
      }, 200);
    }
  }
}
