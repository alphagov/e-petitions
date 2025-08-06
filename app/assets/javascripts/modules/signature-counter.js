class SignatureCounter {
  constructor(container, responseThreshold, debateThreshold, interval) {
    this.responseThreshold = responseThreshold;
    this.debateThreshold = debateThreshold;
    this.baseUrl = window.location.origin + window.location.pathname;
    this.jsonUrl = this.baseUrl + '/count.json';
    this.signatureCount = container.querySelector('.signature-count-number .count');
    this.signatureGoal = container.querySelector('.signature-count-goal');
    this.progressBar = container.querySelector('progress');
    this.value = this.progressBar.value;
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
      const currentCount = this.value;
      const newCount = data.signature_count;
      const threshold = this.currentThreshold(data);

      if (newCount != currentCount) {
        this.countTo(currentCount, newCount, threshold);
        this.updateSignatureGoal(threshold);
        this.updateProgressText(data);
      }
    } catch (error) {
      console.error(error.message);
    }
  }

  format(number) {
    return this.formatter.format(number);
  }

  render(threshold) {
    this.signatureCount.textContent = this.format(this.value);
    this.progressBar.value = Math.floor(this.value);
    this.progressBar.max = Math.max(threshold, this.value);
  }

  countTo(currentCount, newCount, threshold) {
    this.loopCount = 0;
    this.increment = (newCount - currentCount) / 20;

    if (this.interval) {
      clearInterval(this.interval);
    }

    this.interval = setInterval(() => {
      this.value += this.increment;
      this.loopCount++;
      this.render(threshold);

      if (this.loopCount >= 20) {
        clearInterval(this.interval);

        this.value = newCount;
        this.render(threshold);
      }
    }, 50);
  }

  currentThreshold(data) {
    if (data.debate_threshold_reached_at || data.debate_outcome_at) {
      return this.debateThreshold;
    } else if (data.response_threshold_reached_at || data.government_response_at) {
      return this.debateThreshold;
    } else {
      return this.responseThreshold;
    }
  }

  updateSignatureGoal(threshold) {
    const hiddenText = document.createElement('span');

    hiddenText.classList.add('visuallyhidden');
    hiddenText.textContent = this.signatureGoalText(threshold);

    this.signatureGoal.textContent = this.format(threshold);
    this.signatureGoal.appendChild(hiddenText);

  }

  signatureGoalText(threshold) {
    if (threshold > this.responseThreshold) {
      return ' signatures required to be considered for a debate in Parliament';
    } else {
      return ' signatures required to get a government response';
    }
  }

  updateProgressText(data) {
    this.progressBar.textContent = this.progressText(data);
  }

  progressText(data) {
    if (data.debate_outcome_at) {
      if (data.debated) {
        return 'Parliament debated this petition';
      } else {
        return 'Parliament decided not to debate this petition';
      }
    } else if (data.scheduled_debate_date) {
      return 'Parliament will debate this petition';
    } else if (data.debate_threshold_reached_at) {
      return 'This petition will be considered for a debate in Parliament';
    } else if (data.response_threshold_reached_at || data.government_response_at) {
      return `${this.format(data.signature_count)} of ${this.format(this.debateThreshold)} signatures required to be considered for a debate in Parliament`;
    } else {
      return `${this.format(data.signature_count)} of ${this.format(this.responseThreshold)} signatures required to get a government response`;
    }
  }
}

window.PETS = window.PETS || {};
window.PETS.SignatureCounter = SignatureCounter;
