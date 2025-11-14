import CharacterCounter from './modules/character-counter'
import NavigationMenu from './modules/navigation-menu'
import SignatureCounter from './modules/signature-counter'

window.PETS = window.PETS || {};
window.PETS.CharacterCounter = CharacterCounter;
window.PETS.NavigationMenu = NavigationMenu;
window.PETS.SignatureCounter = SignatureCounter;

window.addEventListener('DOMContentLoaded', (event) => {
  const location = window.location;
  const petitionPath = /(?:\/archived)?\/petitions\/\d+/

  if (location.pathname === '/help') {
    if (location.hash === '#petitions-committee') {
      location.hash = "#the-petitions-committee";
    }

    if (location.hash === '#standards') {
      window.location = "/help/standards";
    }
  } else if (location.pathname.match(petitionPath)) {
    if (location.hash === '#response-threshold') {
      location.hash = "#response";
    }

    if (location.hash === '#debate-threshold') {
      location.hash = "#debate";
    }
  }

  const counters = document.querySelectorAll('[data-module=signature-counter]');
  const textareas = document.querySelectorAll('textarea[data-max-length]');

  for (const counter of counters) {
    new SignatureCounter(counter, 10000);
  }

  for (const textarea of textareas) {
    new CharacterCounter(textarea);
  }

  const navigationMenus = document.querySelectorAll('[data-module=navigation-menu]');

  for (const navigationMenu of navigationMenus) {
    new NavigationMenu(navigationMenu);
  }
});
