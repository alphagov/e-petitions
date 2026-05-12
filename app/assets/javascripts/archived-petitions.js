import ParliamentMenu from './modules/parliament-menu';

window.PETS = window.PETS || {};
window.PETS.ParliamentMenu = ParliamentMenu;

window.addEventListener('DOMContentLoaded', (event) => {
  const parliamentMenus = document.querySelectorAll('.parliament-lists > li');

  for (const parliamentMenu of parliamentMenus) {
    new PETS.ParliamentMenu(parliamentMenu);
  }
});
