const app = document.getElementById('app');
const leaveModal = document.getElementById('leave-modal');
const rulesTitle = document.getElementById('rules-title');
const rulesList = document.getElementById('rules-list');
const discordTitle = document.getElementById('discord-title');
const discordSub = document.getElementById('discord-sub');
const discordBanner = document.querySelector('.discord-banner');
const statusBox = document.querySelector('.status-box');
const fields = {
  cash: document.getElementById('cash'),
  bank: document.getElementById('bank'),
  playerId: document.getElementById('player-id'),
  cid: document.getElementById('cid'),
  job: document.getElementById('job'),
  playersOnline: document.getElementById('players-online')
};

const formatMoney = (value) => {
  const number = Number(value || 0);
  return `$${number.toLocaleString('en-US', { maximumFractionDigits: 0 })}`;
};

const setText = (element, value) => {
  if (!element) return;
  element.textContent = value ?? '';
};

const renderRules = (rules = []) => {
  if (!rulesList) return;
  rulesList.innerHTML = '';
  rules.forEach((rule) => {
    const item = document.createElement('li');
    item.textContent = rule;
    rulesList.appendChild(item);
  });
};

const updateData = (data = {}) => {
  setText(fields.cash, formatMoney(data.cash));
  setText(fields.bank, formatMoney(data.bank));
  setText(fields.playerId, data.id ?? '0');
  setText(fields.cid, data.cid ?? 'N/A');
  setText(fields.job, data.job ?? 'Unemployed');
  setText(fields.playersOnline, `${data.onlineCount ?? 0}/${data.onlineMax ?? 0}`);

  if (Array.isArray(data.rules)) {
    renderRules(data.rules);
  }
  if (rulesTitle) {
    setText(rulesTitle, data.rulesTitle ?? 'RP Rules');
  }
  if (discordBanner && data.discordUrl) {
    discordBanner.dataset.url = data.discordUrl;
  }
  if (discordTitle) {
    setText(discordTitle, data.discordLabel ?? 'Join Our Discord');
  }
  if (discordSub) {
    setText(discordSub, data.discordTag ?? data.discordUrl ?? '');
  }
  if (statusBox) {
    statusBox.style.display = data.showStatusBox === false ? 'none' : '';
  }
};

const post = (action, data = {}) => {
  return fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8'
    },
    body: JSON.stringify(data)
  });
};

window.addEventListener('message', (event) => {
  const { action, data } = event.data || {};
  if (action === 'open') {
    updateData(data);
    document.body.classList.add('open');
    app.classList.add('show');
    leaveModal.classList.remove('show');
    leaveModal.setAttribute('aria-hidden', 'true');
  } else if (action === 'close') {
    app.classList.remove('show');
    document.body.classList.remove('open');
    leaveModal.classList.remove('show');
    leaveModal.setAttribute('aria-hidden', 'true');
  } else if (action === 'update') {
    updateData(data);
  }
});

app.addEventListener('click', (event) => {
  const target = event.target.closest('[data-action]');
  if (!target) return;
  const action = target.dataset.action;
  if (!action) return;
  if (action === 'leave') {
    leaveModal.classList.add('show');
    leaveModal.setAttribute('aria-hidden', 'false');
    return;
  }
  if (action === 'discord') {
    const url = target.dataset.url;
    if (url) {
      if (typeof window.invokeNative === 'function') {
        window.invokeNative('openUrl', url);
      } else {
        window.open(url, '_blank');
      }
    }
    post('discord');
    return;
  }
  if (action === 'cancel-leave') {
    leaveModal.classList.remove('show');
    leaveModal.setAttribute('aria-hidden', 'true');
    return;
  }
  if (action === 'confirm-leave') {
    post('quit');
    return;
  }
  post(action);
});

document.addEventListener('keydown', (event) => {
  if (!app.classList.contains('show')) return;
  if (leaveModal.classList.contains('show')) {
    if (event.key === 'Escape') {
      leaveModal.classList.remove('show');
      leaveModal.setAttribute('aria-hidden', 'true');
    }
    return;
  }
  if (event.key === 'Escape') {
    post('close');
  }
});
