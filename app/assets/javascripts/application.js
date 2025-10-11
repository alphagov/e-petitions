import CharacterCounter from './modules/character-counter'
import NavigationMenu from './modules/navigation-menu'
import SignatureCounter from './modules/signature-counter'

window.PETS = window.PETS || {};
window.PETS.CharacterCounter = CharacterCounter;
window.PETS.NavigationMenu = NavigationMenu;
window.PETS.SignatureCounter = SignatureCounter;

window.addEventListener('DOMContentLoaded', (event) => {
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
