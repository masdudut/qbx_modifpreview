function post(name, data = {}) {
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data),
  }).catch(() => {});
}

async function requestNui(name, body) {
  try {
    const r = await fetch(`https://${GetParentResourceName()}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(body || {}),
    });
    return await r.json();
  } catch {
    return null;
  }
}

const root = document.getElementById('root');
const tabsEl = document.getElementById('tabs');
const listEl = document.getElementById('list');

const headersEl = document.getElementById('headers');
const h1Label = document.getElementById('h1Label');
const h2Label = document.getElementById('h2Label');

const h1Btn = document.getElementById('h1Btn');
const h1Text = document.getElementById('h1Text');
const h1Menu = document.getElementById('h1Menu');

const h2Btn = document.getElementById('h2Btn');
const h2Text = document.getElementById('h2Text');
const h2Menu = document.getElementById('h2Menu');

const btnCam = document.getElementById('btnCam');
const btnConfirm = document.getElementById('btnConfirm');
const btnClose = document.getElementById('btnClose');

// header rows: 2 baris di index kamu pakai class headerRow
const headerRows = headersEl ? headersEl.querySelectorAll('.headerRow') : [];
const h1Row = headerRows?.[0] || null;
const h2Row = headerRows?.[1] || null;

let state = {
  tabs: [],
  currentTab: 'paints',
  headersByTab: {},
  optionsByTab: {},
  selected: {},
};

function hide(el){ el?.classList.add('hidden'); }
function show(el){ el?.classList.remove('hidden'); }
function closeMenus(){ hide(h1Menu); hide(h2Menu); }

function setDropdown(ddTextEl, ddMenuEl, items, currentValue, onPick) {
  ddMenuEl.innerHTML = '';
  (items || []).forEach(it => {
    const row = document.createElement('div');
    row.className = 'ddItem' + (String(it.value) === String(currentValue) ? ' active' : '');
    row.textContent = it.label;
    row.onclick = () => { onPick(it.value, it.label); closeMenus(); };
    ddMenuEl.appendChild(row);
  });

  const found = (items || []).find(x => String(x.value) === String(currentValue));
  ddTextEl.textContent = found ? found.label : 'Select';
}

function enableTabDragScroll() {
  let isDown = false, startX = 0, startScroll = 0;

  tabsEl.addEventListener('mousedown', (e) => {
    isDown = true;
    tabsEl.style.cursor = 'grabbing';
    startX = e.pageX;
    startScroll = tabsEl.scrollLeft;
  });

  window.addEventListener('mouseup', () => {
    isDown = false;
    tabsEl.style.cursor = 'grab';
  });

  window.addEventListener('mousemove', (e) => {
    if (!isDown) return;
    const dx = e.pageX - startX;
    tabsEl.scrollLeft = startScroll - dx;
  });

  tabsEl.addEventListener('wheel', (e) => {
    tabsEl.scrollLeft += e.deltaY;
    e.preventDefault();
  }, { passive: false });
}

function renderTabs() {
  tabsEl.innerHTML = '';
  state.tabs.forEach(t => {
    const b = document.createElement('div');
    b.className = 'tab' + (state.currentTab === t.id ? ' active' : '');
    b.textContent = t.label;
    b.onclick = async () => {
      state.currentTab = t.id;
      await refreshDynamicOptions();
      render();
    };
    tabsEl.appendChild(b);
  });
}

async function refreshDynamicOptions() {
  const tab = state.currentTab;

  if (tab === 'paints') {
    const type = state.selected.paints?.type || 'Classic';
    const list = await requestNui('requestPaintOptions', { type });
    state.optionsByTab.paints = Array.isArray(list) ? list : [{ label:'Stock', value:'stock' }];
    return;
  }

  if (tab === 'wheels') {
    const list = await requestNui('requestWheelIndexOptions', {});
    state.optionsByTab.wheels = Array.isArray(list) ? list : [{ label:'Stock', value:-1 }];
    return;
  }

  if (tab === 'body') {
    const partKey = state.selected.body?.part || 'spoiler';
    const list = await requestNui('requestBodyOptions', { partKey });
    state.optionsByTab.body = Array.isArray(list) ? list : [{ label:'Stock', value:-1 }];
    return;
  }
}

function renderHeaders() {
  const tab = state.currentTab;
  const h = state.headersByTab[tab];

  if (!h || h.show === false) {
    hide(headersEl);
    hide(h1Menu); hide(h2Menu);
    return;
  }

  show(headersEl);
  show(h1Row);

  // HARD RULE: H2 hanya boleh tampil di PAINTS
  const showH2 = (tab === 'paints');

  if (showH2) show(h2Row);
  else {
    hide(h2Row);
    hide(h2Menu);
  }

  h1Label.textContent = h.h1Label || 'Category';
  h2Label.textContent = h.h2Label || 'Type';

  // current values
  let h1Current = null;
  let h2Current = null;

  if (tab === 'paints') {
    h1Current = state.selected.paints?.category || 'primary';
    h2Current = state.selected.paints?.type || 'Classic';
  } else if (tab === 'wheels') {
    h1Current = state.selected.wheels?.type ?? 0;
  } else if (tab === 'body') {
    h1Current = state.selected.body?.part || 'spoiler';
  }

  // H1 dropdown (selalu)
  setDropdown(h1Text, h1Menu, h.h1Items || [], h1Current, async (val) => {
    if (tab === 'paints') {
      state.selected.paints.category = String(val);
      post('setHeader', { tab:'paints', which:'h1', value: String(val) });
      await refreshDynamicOptions();
      render();
      return;
    }

    if (tab === 'wheels') {
      state.selected.wheels.type = Number(val);
      state.selected.wheels.index = -1;
      post('setHeader', { tab:'wheels', which:'h1', value: Number(val) });
      await refreshDynamicOptions();
      render();
      return;
    }

    if (tab === 'body') {
      state.selected.body.part = String(val);
      state.selected.body.index = -1;
      post('setHeader', { tab:'body', which:'h1', value: String(val) });
      await refreshDynamicOptions();
      render();
      return;
    }
  });

  // H2 dropdown (PAINTS saja)
  if (showH2) {
    setDropdown(h2Text, h2Menu, h.h2Items || [], h2Current, async (val) => {
      state.selected.paints.type = String(val);
      state.selected.paints.value = 'stock';
      post('setHeader', { tab:'paints', which:'h2', value: String(val) });
      await refreshDynamicOptions();
      render();
    });
  }
}

function getCurrentSelectionForTab(tab) {
  if (tab === 'paints') return state.selected.paints?.value ?? 'stock';
  if (tab === 'wheels') return state.selected.wheels?.index ?? -1;
  if (tab === 'body') return state.selected.body?.index ?? -1;
  if (tab === 'xenon') return state.selected.xenon ?? -1;
  if (tab === 'tint') return state.selected.tint ?? 0;
  if (tab === 'plate') return state.selected.plate ?? 0;
  if (tab === 'horn') return state.selected.horn ?? -1;
  return null;
}

function renderList() {
  listEl.innerHTML = '';
  const tab = state.currentTab;
  const opts = state.optionsByTab[tab] || [];
  const current = String(getCurrentSelectionForTab(tab));

  opts.forEach(o => {
    const val = String(o.value);
    const row = document.createElement('div');
    row.className = 'item' + (val === current ? ' active' : '');

    row.onclick = () => {
      if (tab === 'paints') state.selected.paints.value = o.value;
      else if (tab === 'wheels') state.selected.wheels.index = o.value;
      else if (tab === 'body') state.selected.body.index = o.value;
      else if (tab === 'xenon') state.selected.xenon = o.value;
      else if (tab === 'tint') state.selected.tint = o.value;
      else if (tab === 'plate') state.selected.plate = o.value;
      else if (tab === 'horn') state.selected.horn = o.value;

      post('selectOption', { tab, value: o.value });
      renderList();
    };

    const name = document.createElement('div');
    name.className = 'name';
    name.textContent = o.label;

    const check = document.createElement('div');
    check.className = 'check';
    check.textContent = '✓';

    row.appendChild(name);
    row.appendChild(check);
    listEl.appendChild(row);
  });
}

function render() {
  renderTabs();
  renderHeaders();
  renderList();
}

// dropdown open/close
h1Btn?.addEventListener('click', (e) => {
  e.stopPropagation();
  h1Menu.classList.toggle('hidden');
  hide(h2Menu);
});

h2Btn?.addEventListener('click', (e) => {
  if (state.currentTab !== 'paints') return;
  e.stopPropagation();
  h2Menu.classList.toggle('hidden');
  hide(h1Menu);
});

window.addEventListener('click', () => closeMenus());

// buttons
btnCam?.addEventListener('click', () => post('camera'));
btnConfirm?.addEventListener('click', () => post('confirm'));
btnClose?.addEventListener('click', () => post('cancel'));

window.addEventListener('message', async (e) => {
  const msg = e.data || {};

  if (msg.action === 'open') {
    root.classList.remove('hidden');

    state.tabs = msg.tabs || [];
    state.headersByTab = msg.headersByTab || {};
    state.optionsByTab = msg.optionsByTab || {};
    state.selected = msg.selected || {};
    state.currentTab = msg.currentTab || 'paints';

    state.selected.paints = state.selected.paints || { category:'primary', type:'Classic', value:'stock' };
    state.selected.wheels = state.selected.wheels || { type:0, index:-1 };
    state.selected.body = state.selected.body || { part:'spoiler', index:-1 };

    await refreshDynamicOptions();
    render();
  }

  if (msg.action === 'close') {
    root.classList.add('hidden');
    closeMenus();
  }
});

document.addEventListener('keydown', (ev) => {
  if (ev.key === 'Escape') post('cancel');
});

enableTabDragScroll();
