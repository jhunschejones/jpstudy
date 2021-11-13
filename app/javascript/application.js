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
