import NavigationMenu from './modules/navigation-menu';

window.PETS = window.PETS || {};
window.PETS.NavigationMenu = NavigationMenu;

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

  const navigationMenus = document.querySelectorAll('[data-module=navigation-menu]');

  for (const navigationMenu of navigationMenus) {
    new NavigationMenu(navigationMenu);
  }
});
