export default class NavigationMenu {
  breakpoint;
  menuButton;
  menuIsOpen = false;
  mql = null;

  constructor(container) {
    this.menuButton = container.querySelector('button');
    this.breakpoint = container.dataset.breakpoint;
    this.mql = window.matchMedia(`(min-width: ${this.breakpoint})`);

    if ('addEventListener' in this.mql) {
      this.mql.addEventListener('change', () => this.checkMode());
    } else {
      this.mql.addListener(() => this.checkMode());
    }

    this.menuButton.addEventListener('click', () => {
      this.handleMenuButtonClick();
    });

    this.checkMode();
  }

  checkMode() {
    if (!this.mql || !this.menuButton) {
      return;
    }

    if (this.mql.matches) {
      this.menuButton.setAttribute('hidden', '');
    } else {
      this.menuButton.removeAttribute('hidden');
    }

    this.menuButton.setAttribute('aria-expanded', this.menuIsOpen.toString());
  }

  handleMenuButtonClick() {
    this.menuIsOpen = !this.menuIsOpen;
    this.checkMode();
  }
}
