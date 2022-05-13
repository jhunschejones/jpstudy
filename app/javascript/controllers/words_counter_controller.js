import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "count" ]

  initialize() {
    document.addEventListener("turbo:before-fetch-response", () => {
      this.updateWordCount();
    });
  }

  updateWordCount() {
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
