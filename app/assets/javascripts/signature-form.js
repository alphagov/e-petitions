//= require modules/signature-form

window.addEventListener('DOMContentLoaded', (event) => {
  const signatureForms = document.querySelectorAll('.signature-form');

  for (const signatureForm of signatureForms) {
    new PETS.SignatureForm(signatureForm);
  }
});
