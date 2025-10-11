import CookieManager from './modules/cookie-manager'

window.PETS = window.PETS || {};
window.PETS.CookieManager = CookieManager;

window.addEventListener('DOMContentLoaded', (event) => {
  if (document.getElementById('cookiebannerTemplate')) {
    new CookieManager(document.body);
  }
});
