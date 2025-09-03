import CookieManager from './modules/cookie-manager'
import CharacterCounter from './modules/character-counter'
import SignatureCounter from './modules/signature-counter'

window.PETS = window.PETS || {};
window.PETS.CookieManager = CookieManager;
window.PETS.CharacterCounter = CharacterCounter;
window.PETS.SignatureCounter = SignatureCounter;

window.addEventListener('DOMContentLoaded', (event) => {
  if (document.getElementById('cookiebannerTemplate')) {
    new CookieManager(document.body);
  }

  const counters = document.querySelectorAll('.signature-count');
  const textareas = document.querySelectorAll('textarea[data-max-length]');

  for (const counter of counters) {
    new SignatureCounter(counter, 10000);
  }

  for (const textarea of textareas) {
    new CharacterCounter(textarea);
  }
});
