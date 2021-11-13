// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// https://github.com/hotwired/turbo/issues/294#issuecomment-877842232
// document.addEventListener("turbo:before-fetch-request", (event) => {
//   // Turbo Drive does not send a referrer like turbolinks used to, so let's simulate it here
//   event.detail.fetchOptions.headers["Turbo-Referrer"] = window.location.href;
//   event.detail.fetchOptions.headers["X-Turbo-Nonce"] = document.querySelector("meta[name='csp-nonce']").content;
// });

// https://github.com/hotwired/turbo/issues/294#issuecomment-877842232
// Also borrowing from https://github.com/turbolinks/turbolinks/issues/430
// document.addEventListener("turbo:before-cache", () => {
//   const styleTags = document.querySelectorAll("style");
//   const scriptTags = document.querySelectorAll("script");
//   const pageNonce = document.querySelector("meta[name='csp-nonce']");
//   if (pageNonce) {
//     if (styleTags) {
//       styleTags.forEach(tag => { tag.nonce = pageNonce.content; });
//     }
//     if (scriptTags) {
//       scriptTags.forEach(tag => { tag.nonce = pageNonce.content; });
//     }
//   }
// });

// === some basic keyboard shortcuts for site navigation ===
(function () {
  var keysPressed = {}

  document.onkeydown = function(e) {
    switch (e.key) {
      // letters reflect variant printed with `shift + option + key`
      case "Shift":
        keysPressed["shift"] = true;
        break;
      case "Alt":
        keysPressed["option"] = true;
        break;
      case "Escape":
        keysPressed["escape"] = true;
        break;
      case "Í":
        keysPressed["s"] = true;
        break;
      case "„":
        keysPressed["w"] = true;
        break;
      case "˜":
        keysPressed["n"] = true;
        break;
      case "Å":
        keysPressed["a"] = true;
        break;
      case "Ç":
        keysPressed["c"] = true;
        break;
      case "´":
        keysPressed["e"] = true;
        break;
      case "ˆ":
        keysPressed["i"] = true;
        break;
      case "ˇ":
        keysPressed["t"] = true;
        break;
    }

    if (keysPressed["shift"] && keysPressed["option"] && keysPressed["s"]) {
      e.preventDefault(); // stops key value from being entered into an input field
      return window.location = "/words/search";
    }
    if (keysPressed["shift"] && keysPressed["option"] && keysPressed["w"]) {
      e.preventDefault();
      return window.location = "/words";
    }
    if (
      (keysPressed["shift"] && keysPressed["option"] && keysPressed["n"]) ||
      (keysPressed["shift"] && keysPressed["option"] && keysPressed["a"])
    ) {
      e.preventDefault();
      const newWordBtton = document.querySelector("#new-word-form .new-word");
      if (newWordBtton) {
        return newWordBtton.click();
      }
      return window.location = "/words/new";
    }
    if (keysPressed["shift"] && keysPressed["option"] && keysPressed["c"]) {
      e.preventDefault();
      return window.location = "/words?filter=cards_not_created";
    }
    if (keysPressed["shift"] && keysPressed["option"] && keysPressed["e"]) {
      e.preventDefault();
      return window.location = "/words/export";
    }
    if (keysPressed["shift"] && keysPressed["option"] && keysPressed["i"]) {
      e.preventDefault();
      return window.location = "/words/import";
    }
    if (keysPressed["escape"]) {
      const flashCloseButtons = document.querySelectorAll("#flashes .flash .close-flash-button");
      if (flashCloseButtons.length > 0) {
        e.preventDefault();
        return flashCloseButtons.forEach(button => { button.click(); });
      }

      const newWordBackButton = document.querySelector(".words-list-page #new-word-form .back-button");
      if (newWordBackButton) {
        e.preventDefault();
        return newWordBackButton.click();
      }
    }
  };

  document.onkeyup = function() {
    // reset on key up
    keysPressed = {}
  }
})();
