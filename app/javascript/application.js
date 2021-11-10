// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// https://github.com/hotwired/turbo/issues/294#issuecomment-877842232
document.addEventListener("turbo:before-fetch-request", (event) => {
  // Turbo Drive does not send a referrer like turbolinks used to, so let's simulate it here
  event.detail.fetchOptions.headers["Turbo-Referrer"] = window.location.href;
  event.detail.fetchOptions.headers["X-Turbo-Nonce"] = $("meta[name='csp-nonce']").prop("content");
});

// https://github.com/hotwired/turbo/issues/294#issuecomment-877842232
document.addEventListener("turbo:before-cache", function() {
  let scriptTagsToAddNonces = document.querySelectorAll("script[nonce]");
  for (var element of scriptTagsToAddNonces) {
    element.setAttribute("nonce", element.nonce);
  }
});
