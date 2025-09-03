export default class SignatureForm {
  constructor(form) {
    const locationMenu = form.querySelector('select[name*=location_code]');
    const postcodeInput = form.querySelector('input[name*=postcode]');
    const postcodeRow = form.querySelector('#postcode-row');

    if (locationMenu) {
      if (locationMenu.value && locationMenu.value !== 'GB') {
        postcodeRow.style.display = 'none';
        postcodeInput.value = '';
      }

      locationMenu.addEventListener('change', function(event) {
        if (event.target.value === 'GB') {
          postcodeRow.style.display = '';
        } else {
          postcodeRow.style.display = 'none';
          postcodeInput.value = '';
        }
      });
    }
  }
}
