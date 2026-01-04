// ============================
// QBX_MODIFPREVIEW - NUI APP.JS (FINAL, MATCH index.html + nui.lua)
// - Paints: 2 dropdown
// - Wheels: 1 dropdown (Wheel Type only)
// - Body:   1 dropdown (Body Part only)
// ============================

function post(name, data = {}) {
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
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
  } catch (e) {
    return null;
  }
}

// ===== DOM (match index.html) =====
const root = document.getElementById('root');

const subtitle = document.getElementById('subtitle');

const btnCam = document.getElementById('btnCam');
const btnConfirm = document.getElementById('btnConfirm');
const btnClose = document.getElementById('btnClose');

const tabsEl = document.getElementById('tabs');

const headersEl = document.getElementById('headers');
const h1Row = document.getElementById('h1Row');
const h2Row = document.getElementById('h2Row');

const h1Label = document.getElementById('h1Label');
const h2Label = document.getElementById('h2Label');

const h1Btn = document.getElementById('h1Btn');
const h2Btn = document.getElementById('h2Btn');

const h1Text = document.getElementById('h1Text');
const h2Text = document.getElementById('h2Text');

const h1Menu = document.getElementById('h1Menu');
const h2Menu = document.getElementById('h2Menu');

const sectionTitle = document.getElementById('sectionTitle');
const listEl = document.getElementById('list');

// ===== helpers =====
function hide(el) { el && el.classList.add('hidden'); }
function show(el) { el && el.classList.remove('hidden'); }

function closeMenus() {
  hide(h1Menu);
  hide(h2Menu);
}

function setBodyTab(tab) {
  // buat fallback CSS kamu tetap jalan
  document.body.dataset.tab = tab || '';
}

function setDropdown(menuEl, items, currentValue, onPick) {
  menuEl.innerHTML = '';
  (items || []).forEach(it => {
    const row = document.createElement('div');
    row.className = 'ddItem' + (String(it.value) === String(currentValue) ? ' active' : '');
    row.textContent = it.label ?? String(it.value);
    row.onclick = () => { onPick(it.value); closeMenus(); };
    menuEl.appendChild(row);
  });
}

function setText(el, txt) {
  if (!el) return;
  el.textContent = (txt === undefined || txt === null || txt === '') ? 'Select' : String(txt);
}

// ===== STATE =====
const state = {
  open: false,
  tabs: [],
  currentTab: 'paints',
  headersByTab: {},
  optionsByTab: {},
  selected: {
    paints: { category: 'primary', type: 'Classic', value: 'stock' },
    wheels: { type: 0, value: -1 },
    body: { part: 'spoiler', value: -1 },
    xenon: { value: -1 },
    tint: { value: 0 },
    plate: { value: 0 },
    horn: { value: -1 }
  }
};

// ====== logic: show/hide headers ======
function showHeaders(showHeader, showH2) {
  if (!headersEl) return;

  if (!showHeader) {
    hide(headersEl);
    closeMenus();
    return;
  }

  show(headersEl);
  show(h1Row);

  if (showH2) {
    show(h2Row);
  } else {
    hide(h2Row);
    hide(h2Menu);
    setText(h2Text, '');
  }
}

// ====== ensure options for tab (based on nui.lua callbacks) ======
async function ensureOptionsForTab(tab) {
  if (!tab) return;

  // kalau sudah ada dan bukan paints/body yang butuh refresh, biarkan
  // (tapi saat header berubah, kita akan panggil lagi)
  if (Array.isArray(state.optionsByTab[tab]) && state.optionsByTab[tab].length) return;

  if (tab === 'wheels') {
    const list = await requestNui('requestWheelIndexOptions', {});
    state.optionsByTab.wheels = Array.isArray(list) ? list : [{ label: 'Stock', value: -1 }];
    return;
  }

  if (tab === 'body') {
    const partKey = state.selected.body?.part || 'spoiler';
    const list = await requestNui('requestBodyOptions', { partKey });
    state.optionsByTab.body = Array.isArray(list) ? list : [{ label: 'Stock', value: -1 }];
    return;
  }

  if (tab === 'paints') {
    // requestPaintOptions pakai groupId/type
    const type = state.selected.paints?.type || 'Classic';
    const list = await requestNui('requestPaintOptions', { type });
    state.optionsByTab.paints = Array.isArray(list) ? list : [{ label: 'Stock', value: 'stock' }];
    return;
  }
}

// ====== render tabs ======
function renderTabs() {
  if (!tabsEl) return;
  tabsEl.innerHTML = '';

  (state.tabs || []).forEach(t => {
    const b = document.createElement('div');
    b.className = 'tab' + (state.currentTab === t.id ? ' active' : '');
    b.textContent = t.label || t.id;

    b.onclick = async () => {
      state.currentTab = t.id;
      setBodyTab(state.currentTab);
      closeMenus();
      await ensureOptionsForTab(state.currentTab);
      render();
    };

    tabsEl.appendChild(b);
  });
}

// ====== render headers (dropdowns) ======
function renderHeaders() {
  const tab = state.currentTab;
  const h = state.headersByTab?.[tab];

  if (!h || h.show === false) {
    showHeaders(false, false);
    return;
  }

  // ✅ FIX UTAMA: H2 hanya muncul di PAINTS
  const showH2 = (tab === 'paints') && !!h.showH2;
  showHeaders(true, showH2);

  // labels
  setText(h1Label, h.h1Label || 'Category');
  setText(h2Label, h.h2Label || 'Type');

  // current value display
  if (tab === 'paints') {
    const cat = state.selected.paints?.category || 'primary';
    const typ = state.selected.paints?.type || 'Classic';
    setText(h1Text, (h.h1Items || []).find(x => String(x.value) === String(cat))?.label || cat);
    setText(h2Text, (h.h2Items || []).find(x => String(x.value) === String(typ))?.label || typ);

    // H1 menu
    setDropdown(h1Menu, h.h1Items || [], cat, async (val) => {
      state.selected.paints.category = String(val);
      state.selected.paints.value = 'stock';
      post('setHeader', { tab: 'paints', which: 'h1', value: String(val) });

      // biasanya category akan mengubah daftar group/type (di server/lua),
      // jadi tunggu update message dari lua. Tapi untuk opsi list paints,
      // kita refresh pakai type yang sekarang tetap.
      await ensureOptionsForTab('paints');
      render();
    });

    // H2 menu (only paints)
    if (showH2) {
      setDropdown(h2Menu, h.h2Items || [], typ, async (val) => {
        state.selected.paints.type = String(val);
        state.selected.paints.value = 'stock';
        post('setHeader', { tab: 'paints', which: 'h2', value: String(val) });

        // refresh list cat warna
        const list = await requestNui('requestPaintOptions', { type: String(val) });
        state.optionsByTab.paints = Array.isArray(list) ? list : [{ label: 'Stock', value: 'stock' }];
        render();
      });
    }

    return;
  }

  // Wheels: hanya H1
  if (tab === 'wheels') {
    const type = state.selected.wheels?.type ?? 0;
    setText(h1Text, (h.h1Items || []).find(x => String(x.value) === String(type))?.label || type);

    setDropdown(h1Menu, h.h1Items || [], type, async (val) => {
      state.selected.wheels.type = Number(val);
      state.selected.wheels.value = -1;
      post('setHeader', { tab: 'wheels', which: 'h1', value: Number(val) });

      // refresh wheel index list
      state.optionsByTab.wheels = [];
      await ensureOptionsForTab('wheels');
      render();
    });

    return;
  }

  // Body: hanya H1
  if (tab === 'body') {
    const part = state.selected.body?.part || 'spoiler';
    setText(h1Text, (h.h1Items || []).find(x => String(x.value) === String(part))?.label || part);

    setDropdown(h1Menu, h.h1Items || [], part, async (val) => {
      state.selected.body.part = String(val);
      state.selected.body.value = -1;
      post('setHeader', { tab: 'body', which: 'h1', value: String(val) });

      // refresh body index list by partKey
      state.optionsByTab.body = [];
      await ensureOptionsForTab('body');
      render();
    });

    return;
  }

  // other tabs (xenon/tint/plate/horn) => tidak pakai H2, tapi jika ada H1Items kita render H1
  const cur = state.selected?.[tab]?.value ?? null;
  setText(h1Text, (h.h1Items || []).find(x => String(x.value) === String(cur))?.label || cur);

  setDropdown(h1Menu, h.h1Items || [], cur, async (val) => {
    // tab lain: cukup setHeader jika lua memang pakai header, tapi di nui.lua setHeader hanya handle paints/wheels/body
    // jadi kita cuma update display lokal.
    if (!state.selected[tab]) state.selected[tab] = {};
    state.selected[tab].value = val;
    render();
  });
}

// ====== render list/options ======
function renderOptions() {
  const tab = state.currentTab;
  const opts = state.optionsByTab?.[tab] || [];
  listEl.innerHTML = '';

  if (!opts.length) {
    sectionTitle.textContent = 'Select an option';
    const empty = document.createElement('div');
    empty.className = 'empty';
    empty.textContent = 'Select an option';
    listEl.appendChild(empty);
    return;
  }

  sectionTitle.textContent = 'Select an option';

  const selectedValue =
    tab === 'paints' ? (state.selected.paints?.value ?? 'stock') :
    tab === 'wheels' ? (state.selected.wheels?.value ?? -1) :
    tab === 'body'   ? (state.selected.body?.value ?? -1) :
    (state.selected?.[tab]?.value ?? null);

  opts.forEach(opt => {
    const item = document.createElement('div');
    item.className = 'item' + (String(opt.value) === String(selectedValue) ? ' active' : '');

    const name = document.createElement('div');
    name.className = 'name';
    name.textContent = opt.label ?? String(opt.value);

    const check = document.createElement('div');
    check.className = 'check';
    check.textContent = '✓';

    item.appendChild(name);
    item.appendChild(check);

    item.onclick = () => {
      // simpan selected lokal
      if (tab === 'paints') state.selected.paints.value = String(opt.value);
      else if (tab === 'wheels') state.selected.wheels.value = Number(opt.value);
      else if (tab === 'body') state.selected.body.value = Number(opt.value);
      else {
        if (!state.selected[tab]) state.selected[tab] = {};
        state.selected[tab].value = opt.value;
      }

      // kirim ke lua (nui.lua: selectOption)
      post('selectOption', { tab, value: opt.value });
      render();
    };

    listEl.appendChild(item);
  });
}

// ===== render all =====
function render() {
  if (!state.open) {
    hide(root);
    return;
  }

  show(root);
  setBodyTab(state.currentTab);

  renderTabs();
  renderHeaders();
  renderOptions();
}

// ===== UI events =====
btnConfirm?.addEventListener('click', () => post('confirm', {}));
btnClose?.addEventListener('click', () => post('cancel', {}));
btnCam?.addEventListener('click', () => post('camera', {}));

h1Btn?.addEventListener('click', () => {
  hide(h2Menu);
  h1Menu.classList.contains('hidden') ? show(h1Menu) : hide(h1Menu);
});

h2Btn?.addEventListener('click', () => {
  hide(h1Menu);
  h2Menu.classList.contains('hidden') ? show(h2Menu) : hide(h2Menu);
});

document.addEventListener('click', (e) => {
  const t = e.target;
  if (!t) return;

  const insideH1 = h1Btn?.contains(t) || h1Menu?.contains(t);
  const insideH2 = h2Btn?.contains(t) || h2Menu?.contains(t);

  if (!insideH1) hide(h1Menu);
  if (!insideH2) hide(h2Menu);
});

// ESC / BACKSPACE
document.addEventListener('keydown', (e) => {
  if (!state.open) return;

  if (e.key === 'Escape') {
    e.preventDefault();
    post('cancel', {});
  }

  // Backspace: balik dari camera
  if (e.key === 'Backspace') {
    e.preventDefault();
    post('camera_back', {});
  }
});

// ===== NUI messages from Lua =====
window.addEventListener('message', async (event) => {
  const data = event.data || {};

  if (data.action === 'open') {
    state.open = true;

    if (subtitle && data.subtitle) subtitle.textContent = data.subtitle;

    state.tabs = data.tabs || state.tabs;
    state.headersByTab = data.headersByTab || state.headersByTab;
    state.optionsByTab = data.optionsByTab || state.optionsByTab;
    state.selected = data.selected || state.selected;

    // lua pakai currentTab
    state.currentTab = data.currentTab || 'paints';

    // pastikan options ada untuk tab awal
    await ensureOptionsForTab(state.currentTab);

    render();
    return;
  }

  if (data.action === 'close') {
    state.open = false;
    closeMenus();
    render();
    return;
  }

  if (data.action === 'update') {
    // lua bisa mengirim update parsial
    if (data.tabs) state.tabs = data.tabs;
    if (data.headersByTab) state.headersByTab = data.headersByTab;
    if (data.optionsByTab) state.optionsByTab = data.optionsByTab;
    if (data.selected) state.selected = data.selected;
    if (data.currentTab) state.currentTab = data.currentTab;

    await ensureOptionsForTab(state.currentTab);
    render();
    return;
  }
});

// init
render();
