class SignatureForm {
  constructor(form) {
    const locationMenu = form.querySelector('select[name*=location_code]');
    const postcodeInput = form.querySelector('input[name*=postcode]');
    const postcodeRow = form.querySelector('#postcode-row');

    if (locationMenu) {
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

window.PETS = window.PETS || {};
window.PETS.SignatureForm = SignatureForm;
