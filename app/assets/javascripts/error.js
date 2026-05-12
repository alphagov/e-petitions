import NavigationMenu from './modules/navigation-menu';

window.PETS = window.PETS || {};
window.PETS.NavigationMenu = NavigationMenu;

window.addEventListener('DOMContentLoaded', (event) => {
  const navigationMenus = document.querySelectorAll('[data-module=navigation-menu]');

  for (const navigationMenu of navigationMenus) {
    new NavigationMenu(navigationMenu);
  }
});
