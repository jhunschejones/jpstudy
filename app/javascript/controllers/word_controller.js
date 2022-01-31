import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "wordCard" ]

  static values = {
    cardsCreated: Boolean,
    applyJsFilters: Boolean,
    japaneseWord: String,
    englishWord: String,
    addedAt: String,
    createdAt: String,
    databaseId: String,
    wordId: String
  }

  connect() {
    // Only filter in JS if this is a new word added by turbo_stream
    if (!this.applyJsFilters()) {
      return;
    }
    // gotta set this back so that we don't go through the hiding loop again
    this.applyJsFiltersValue = false;

    const thisTurboFrame = this.wordCardTarget.closest("turbo-frame");

    // Apply cards already created filter
    if (this.filterWordsWithCardsAlreadyCreated() && this.cardsAlreadyCreated()) {
      return thisTurboFrame.parentNode.removeChild(thisTurboFrame);
    }
    // Apply search filter
    if (this.searchFilter() && !this.wordMatchesSearchFilter()) {
      return thisTurboFrame.parentNode.removeChild(thisTurboFrame);
    }
    // Apply oldest-first card order filter
    if (this.showOldestCardsFirst()) {
      if (!this.placeAmongExistingCards()) {
        return thisTurboFrame.parentNode.removeChild(thisTurboFrame);
      }
    }
  }

  // === Private ===

  applyJsFilters() {
    return this.applyJsFiltersValue;
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
    const allOtherWords = document.querySelectorAll(`.word:not(.skeleton-word):not(.${this.wordIdValue})`);
    const allOtherWordsSortableFields = Array
      .from(allOtherWords)
      .map((word) => {
        return {
          addedAt: new Date(word.dataset.wordAddedAtValue),
          createdAt: new Date(word.dataset.wordCreatedAtValue),
          databaseId: parseInt(word.dataset.wordDatabaseIdValue)
        }
      });

    // assuming we're in decending order here, as is the current usecase
    const newestSortableFields = allOtherWordsSortableFields[allOtherWordsSortableFields.length - 1];
    const thisWordSortableFields = {
      addedAt: new Date(this.addedAtValue),
      createdAt: new Date(this.createdAtValue),
      databaseId: parseInt(this.databaseIdValue)
    };

    // If the newest date on the page is still earlier than this date, and there
    // is a multiple of the max words per page on the page, return false.
    // This will prevent us from adding new words when showing oldest first.
    // The new word will then appear for real when the page is scrolled to.
    if (newestSortableFields.addedAtValue <= thisWordSortableFields.addedAtValue && allOtherWords.length % 10 == 0) {
      return false;
    }

    // find where the date fits in the array of dates and place the card
    const insertBeforeIndex = this.indexToInsertAt(allOtherWordsSortableFields, thisWordSortableFields);
    const thisTurboFrame = this.element.closest("turbo-frame");
    thisTurboFrame.parentNode.removeChild(thisTurboFrame);
    if (insertBeforeIndex == allOtherWords.length) {
      // the word should go last
      allOtherWords[allOtherWords.length - 1].closest("turbo-frame").parentNode.appendChild(thisTurboFrame);
    } else {
      // the word should go in the middle somewhere
      allOtherWords[insertBeforeIndex].closest("turbo-frame").parentNode.insertBefore(thisTurboFrame, allOtherWords[insertBeforeIndex].closest("turbo-frame"));
    }
    return true;
  }

  // Adapted from https://www.freecodecamp.org/news/how-to-find-the-index-where-a-number-belongs-in-an-array-in-javascript-9af8453a39a8/
  indexToInsertAt(array, newElement) {
    let newArray = array.concat(newElement);
    // Sort the new array from greatest to least.
    newArray.sort((a, b) => {
      return (a.addedAt - b.addedAt || a.createdAt - b.createdAt || a.databaseId - b.databaseId);
      // return (a.databaseId - b.databaseId || a.createdAt - b.createdAt || a.addedAt - b.addedAt);
    });
    // newArray.sort((a, b) => b - a);
    // Return the index of the new element which is now in the correct place in the new array.
    return newArray.indexOf(newElement);
  }
}
