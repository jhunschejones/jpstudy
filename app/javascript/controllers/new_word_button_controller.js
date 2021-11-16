import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Remove filters before loading the form when adding a new word from the words list page
  disableFilters(event) {
    if (location.search.length > 0) {
      event.preventDefault();
      event.stopImmediatePropagation();
      return window.location = "/words?message_code=001";
    }
  }
}
