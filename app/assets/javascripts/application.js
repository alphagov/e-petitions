//= require modules/cookie-manager

window.addEventListener('DOMContentLoaded', () => {
  if (document.getElementById('cookiebannerTemplate')) {
    new PETS.CookieManager(document.body);
  }
});
