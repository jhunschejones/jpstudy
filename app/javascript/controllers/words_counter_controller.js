import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "count" ]

  initialize() {
    this.boundUpdateWordCount = this.updateWordCount.bind(this);
    this.initializedOnHref = window.location.href;
  }

  connect() {
    document.addEventListener("turbo:before-fetch-response", this.boundUpdateWordCount);
  }

  disconnect() {
    document.removeEventListener("turbo:before-fetch-response", this.boundUpdateWordCount);
  }

  updateWordCount() {
    // Since this method is called on turbo:before-fetch-response, it is possible
    // that the user has changed pages but we have not yet called `disconnect()`
    // on the stimulus controller itself. In that case, just return early instead
    // of trying to make the network request for the updated words count.
    if (window.location.href != this.initializedOnHref) {
      return;
    }

    const url = new URL(window.location);
    url.pathname = `${url.pathname}/count`;
    fetch(url, {
      method: "GET",
      credentials: "same-origin",
      headers: { Accept: "application/json" }
    }).then((response) => response.json()
    ).then(responseBody => {
      if (responseBody.wordsCount == 1) {
        this.countTarget.innerText = "(1 word matches)";
      } else {
        this.countTarget.innerText = `(${responseBody.wordsCount} words match)`;
      }
    }).catch(error => console.error(`Error getting word count: ${error}`));
  }
}
