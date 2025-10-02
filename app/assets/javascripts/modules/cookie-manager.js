const parseCookieValues = function (cookies) {
  return cookies
    .split(';')
    .map((item) => item.trimLeft())
    .map((item) => {
      return [
        item.substring(0, item.indexOf('=')),
        decodeURIComponent(item.substring(item.indexOf('=') + 1))
      ];
    })
}

const getCookieValues = function (cookies) {
  return Object.fromEntries(parseCookieValues(cookies));
}

const getCookieValue = function (cookies, name) {
  return getCookieValues(cookies)[name];
}

const getCookieValueObject = function (cookies, name) {
  const value = getCookieValue(cookies, name);
  return value ? JSON.parse(atob(value)) : {};
}

const buildCookie = function (name, value) {
  const date = new Date();
  date.setDate(date.getDate() + 365);

  const cookie = [
    `${name}=${encodeURIComponent(value)}`,
    `domain=${window.location.hostname}`,
    `expires=${date.toUTCString()}`,
    `path=/`
  ];

  return cookie.join('; ');
}

class CookieBanner {
  constructor(root, manager) {
    const template = document.getElementById('cookiebannerTemplate');
    template.remove();

    const element = template.content.cloneNode(true);
    root.insertBefore(element, root.firstChild);

    this.element = document.getElementById('cookiebanner');
    const acceptButton = document.getElementById('acceptCookies');
    const rejectButton = document.getElementById('rejectCookies');
    const manageButton = document.getElementById('manageCookies');

    acceptButton.addEventListener('click', () => {
      manager.saveCookiePreferences(true);
    });

    rejectButton.addEventListener('click', () => {
      manager.saveCookiePreferences(false);
    });

    manageButton.addEventListener('click', () => {
      manager.preferences.show();
    });
  }

  show() {
    this.element.style.display = 'block';
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  hide() {
    this.element.style.display = 'none';
  }
}

class CookiePreferences {
  constructor(root, manager) {
    const template = document.getElementById('cookiepreferencesTemplate');
    template.remove();

    const element = template.content.cloneNode(true);
    root.append(element);

    this.preferences = document.getElementById('cookiepreferences');
    this.overlay = this.preferences.previousElementSibling;

    this.form = document.getElementById('preferencesForm');
    this.analyticsCookies = this.form.elements['analyticsCookies'];

    const saveButton = document.getElementById('savePreferences');
    const closeButton = document.getElementById('closePreferences');

    saveButton.addEventListener('click', () => {
      manager.saveCookiePreferences(this.allowAnalyticsCookies);
    });

    closeButton.addEventListener('click', () => {
      manager.closeCookiePreferences();
    });
  }

  toggle(visibility) {
    document.body.classList.toggle('cookie-overlay-open', visibility);
    this.overlay.style.display = visibility ? 'block' : 'none';
    this.preferences.style.display = visibility ? 'block' : 'none';
  }

  show(analytics = false) {
    this.toggle(true);
    this.analyticsCookies.value = analytics ? 'true' : false;

    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  hide() {
    this.toggle(false);
  }

  get allowAnalyticsCookies() {
    return this.analyticsCookies.value == 'true';
  }
}

class CookieManager {
  constructor(root) {
    this.cookieName = 'uk-parliament.cookie-policy';
    this.alternateCookieName = 'petition-cookie-policy';

    const defaultCookie = {
      analytics: false,
      marketing: false,
      preferences_set: false
    }

    const documentCookie = getCookieValueObject(document.cookie, this.cookieName);
    this.policyCookie = Object.assign(defaultCookie, documentCookie);

    this.preferences = new CookiePreferences(root, this, this.policyCookie);
    this.banner = new CookieBanner(root, this, this.policyCookie);

    const cookiePolicyLink = document.getElementById('cookiePolicyLink');
    cookiePolicyLink.textContent = 'Cookie policy';

    const cookiePreferencesLink = document.createElement('a');
    cookiePreferencesLink.textContent = 'Cookie settings';
    cookiePreferencesLink.href = '#';

    const cookiePolicyLinkWrapper = cookiePolicyLink.parentNode;
    const cookiePreferencesLinkWrapper = document.createElement('li');

    cookiePreferencesLinkWrapper.append(cookiePreferencesLink);
    cookiePolicyLinkWrapper.after(cookiePreferencesLinkWrapper);

    cookiePreferencesLinkWrapper.addEventListener('click', (event) => {
      event.preventDefault();
      this.preferences.show(this.allowAnalyticsCookies);
    });

    if (!this.preferencesSet) {
      this.banner.show();
    }
  }

  saveCookiePreferences(accept) {
    this.banner.hide();
    this.preferences.hide();

    this.policyCookie.analytics = accept;
    this.policyCookie.marketing = false;
    this.policyCookie.preferences_set = true;

    const json = JSON.stringify(this.policyCookie);

    document.cookie = buildCookie(this.cookieName, btoa(json));
    document.cookie = buildCookie(this.alternateCookieName, json);

    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push({ 'event': 'cookie_pref_set' });
  }

  closeCookiePreferences() {
    this.preferences.hide();

    if (this.preferencesSet) {
      this.banner.hide();
    }
  }

  get allowAnalyticsCookies() {
    return this.policyCookie.analytics;
  }

  get preferencesSet() {
    return this.policyCookie.preferences_set;
  }
}

window.PETS = window.PETS || {};
window.PETS.CookieManager = CookieManager;
