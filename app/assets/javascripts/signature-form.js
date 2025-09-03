import SignatureForm from './modules/signature-form'

window.PETS = window.PETS || {};
window.PETS.SignatureForm = SignatureForm;

window.addEventListener('DOMContentLoaded', (event) => {
  const signatureForms = document.querySelectorAll('.signature-form');

  for (const signatureForm of signatureForms) {
    new PETS.SignatureForm(signatureForm);
  }
});
