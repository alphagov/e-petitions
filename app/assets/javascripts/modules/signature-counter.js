class SignatureCounter {
  constructor(container, responseThreshold, debateThreshold, interval) {
    this.responseThreshold = responseThreshold;
    this.debateThreshold = debateThreshold;
    this.baseUrl = window.location.origin + window.location.pathname;
    this.jsonUrl = this.baseUrl + '/count.json';
    this.signatureCount = container.querySelector('.signature-count-number .count');
    this.signatureGoal = container.querySelector('.signature-count-goal');
    this.progressBar = container.querySelector('progress');
    this.formatter = new Intl.NumberFormat('en-GB', { maximumFractionDigits: 0 });

    setInterval(async () => { await this.fetchCount() }, interval);
  }

  async fetchCount() {
    try {
      const response = await fetch(this.jsonUrl);

      if (!response.ok) {
        throw new Error(`Response status: ${response.status}`);
      }

      const data = await response.json();
      const current = this.progressBar.value;

      if (data.signature_count != current) {
        this.countTo(current, data.signature_count)
      }
    } catch (error) {
      console.error(error.message);
    }
  }

  format(number) {
    return this.formatter.format(number);
  }

  getThreshold(signatureCount) {
    if (signatureCount >= this.responseThreshold) {
      return this.debateThreshold;
    } else {
      return this.responseThreshold;
    }
  }

  render() {
    const threshold = this.getThreshold(this.value);

    this.signatureCount.textContent = this.format(this.value);
    this.signatureGoal.textContent = this.format(threshold);
    this.progressBar.value = Math.floor(this.value);
    this.progressBar.max = Math.max(threshold, this.value);
  }

  countTo(currentCount, newCount) {
    this.value = currentCount;
    this.loopCount = 0;
    this.increment = (newCount - currentCount) / 20;

    this.interval = setInterval(() => {
      this.value += this.increment;
      this.loopCount++;
      this.render();

      if (this.loopCount >= 20) {
        clearInterval(this.interval);

        this.value = newCount
        this.render();
      }
    }, 50);
  }
}

window.PETS = window.PETS || {};
window.PETS.SignatureCounter = SignatureCounter;
