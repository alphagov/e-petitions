window.addEventListener('DOMContentLoaded', () => {
  const button = document.getElementById('copy-petition');
  const action = document.getElementById('petition-action');
  const background = document.getElementById('petition-background');
  const additionalDetails = document.getElementById('petition-additional-details');

  button.addEventListener('click', async () => {
    const content = `${action.value}\n\n${background.value}\n\n${additionalDetails.value}\n`;

    try {
      await navigator.clipboard.writeText(content);
      alert('Copied petition to the clipboard');
    } catch (error) {
      console.error(error.message);
      alert('Unable to copy petition to the clipboard');
    }
  })
});
