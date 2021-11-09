import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "wordCard" ]

  static values = {
    cardsCreated: Boolean
  }

  connect() {
    if (this.filterWordsWithCardsAlreadyCreated() && this.cardsAlreadyCreated()) {
      this.wordCardTarget.classList.add("hidden");
    }
  }

  filterWordsWithCardsAlreadyCreated() {
    return new URLSearchParams(location.search).get("filter") === "cards_not_created"
  }

  cardsAlreadyCreated() {
    return this.cardsCreatedValue
  }
}
