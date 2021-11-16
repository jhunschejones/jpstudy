import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "wordCard" ]

  static values = {
    cardsCreated: Boolean,
    isNewWord: Boolean,
    japaneseWord: String,
    englishWord: String,
    addedOn: String,
    wordId: String
  }

  connect() {
    // Only filter in JS if this is a new word added by turbo_stream
    if (!this.isNewWord()) {
      return;
    }

    // Apply cards already created filter
    if (this.filterWordsWithCardsAlreadyCreated() && this.cardsAlreadyCreated()) {
      this.wordCardTarget.classList.add("hidden");
    }
    // Apply search filter
    if (this.searchFilter() && !this.wordMatchesSearchFilter()) {
      this.wordCardTarget.classList.add("hidden");
    }
    // Apply oldest-first card order filter
    if (this.showOldestCardsFirst()) {
      if (!this.placeAmongExistingCards()) {
        this.wordCardTarget.classList.add("hidden");
      }
    }

    // gotta set this so that we don't go through the hiding loop again!
    this.isNewWordValue = false;
  }

  // === Private ===

  isNewWord() {
    return this.isNewWordValue;
  }

  filterWordsWithCardsAlreadyCreated() {
    return new URLSearchParams(location.search).get("filter") === "cards_not_created";
  }

  cardsAlreadyCreated() {
    return this.cardsCreatedValue;
  }

  searchFilter() {
    return new URLSearchParams(location.search).get("search");
  }

  wordMatchesSearchFilter() {
    const search = this.searchFilter();
    return this.japaneseWordValue.includes(search) ||
      this.englishWordValue.toLowerCase().includes(search.toLowerCase());
  }

  showOldestCardsFirst() {
    return new URLSearchParams(location.search).get("order") === "oldest_first";
  }

  // return false if should not place, true after element is placed
  placeAmongExistingCards() {
    const existingAddedOnSpans = document.querySelectorAll(`.word:not(.${this.wordIdValue}) .source .added-on`);
    const existingDates = Array
      .from(existingAddedOnSpans)
      .map((span) => new Date(span.innerText.replace("Added ", "")));
    // assuming we're in decending order here, as is the current usecase
    const newestDate = existingDates[existingDates.length - 1];
    const thisWordsDate = new Date(this.addedOnValue);
    if (newestDate >= thisWordsDate) {
      return false;
    }
    // find where the date fits in the array of dates and place the card
    const insertBeforeIndex = this.indexToInsertAt(existingDates, thisWordsDate);
    const thisTurboFrame = this.element.parentNode;
    thisTurboFrame.parentNode.removeChild(thisTurboFrame);
    existingAddedOnSpans[insertBeforeIndex].closest("turbo-frame").parentNode.appendChild(thisTurboFrame);
    return true;
  }

  // Adapted from https://www.freecodecamp.org/news/how-to-find-the-index-where-a-number-belongs-in-an-array-in-javascript-9af8453a39a8/
  indexToInsertAt(array, newElement) {
    let newArray = array.concat(newElement);
    // Sort the new array from greatest to least.
    newArray.sort((a, b) => b - a);
    // Return the index of the new element which is now in the correct place in the new array.
    return newArray.indexOf(newElement);
  }
}
