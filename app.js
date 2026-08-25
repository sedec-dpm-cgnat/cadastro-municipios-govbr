const stateCodes = [11, 12, 13, 14, 15, 16, 17, 21, 22, 23, 24, 25, 26, 27, 28, 29, 31, 32, 33, 35, 41, 42, 43, 50, 51, 52, 53];
const geometryBase = 'https://servicodados.ibge.gov.br/api/v3/malhas';
const indicatedCodes = window.CNM_INDICATED_CODES instanceof Set ? window.CNM_INDICATED_CODES : new Set();
const registeredCodes = new Set(['4314902', '3304557', '3550308', '2611606', '1302603']);
const inProgressCodes = new Set(['3550704']);
let selectedProfile = null;
let nationalMap = null;
let municipalLayer = null;
let stateLayer = null;
let registeredLayer = null;
let mapDataPromise = null;
let currentMapFilter = 'all';

const profiles = {
  municipal: {
    title: 'Município',
    scope: 'Município selecionado pelo usuário e processos vinculados ao seu código IBGE.',
    copy: 'Inscrição, manifestação, upload da comprovação e acompanhamento das obrigações.',
    permissions: ['Iniciar e editar o cadastro municipal', 'Enviar a comprovação da área de risco', 'Manifestar concordância quando o município for indicado', 'Acompanhar análise, pendências e documentos próprios'],
    workspace: 'municipal'
  },
  estadual: {
    title: 'Estado',
    scope: 'Municípios do estado autorizado e demandas de apoio regional.',
    copy: 'Acompanhamento regional, orientação técnica e consulta a indicadores agregados.',
    permissions: ['Consultar municípios do estado vinculado', 'Acompanhar inscrições e pendências regionais', 'Registrar apoio técnico e encaminhamentos', 'Exportar relatórios do escopo estadual'],
    workspace: 'readonly'
  },
  federal: {
    title: 'União',
    scope: 'Base nacional conforme unidade administrativa e transações concedidas.',
    copy: 'Gestão nacional das indicações, análise, publicação e administração do cadastro.',
    permissions: ['Gerenciar listas técnicas e fontes de referência', 'Analisar inscrições e registrar decisões', 'Publicar dados públicos e relatórios nacionais', 'Administrar perfis operacionais autorizados'],
    workspace: 'readonly'
  },
  controle: {
    title: 'Controle e fiscalização',
    scope: 'Dados públicos e, mediante autorização formal, trilhas de auditoria do escopo concedido.',
    copy: 'Consulta, auditoria e exportação sem permissão para alterar documentos ou situações cadastrais.',
    permissions: ['Consultar mapa e listas públicas', 'Consultar trilhas de auditoria autorizadas', 'Exportar evidências e relatórios de fiscalização', 'Solicitar informação complementar sem editar o cadastro'],
    workspace: 'readonly'
  }
};

function $(selector) { return document.querySelector(selector); }
function $$(selector) { return [...document.querySelectorAll(selector)]; }

function scrollToSection(id) {
  const target = document.getElementById(id);
  if (target) target.scrollIntoView({ behavior: 'smooth', block: 'start' });
  $$('.nav-link').forEach(link => link.classList.toggle('active', link.dataset.scroll === id));
}

function openModal(title, copy) {
  $('#modal-title').textContent = title;
  $('#modal-copy').textContent = copy;
  $('#demo-modal').hidden = false;
  $('#modal-ok').focus();
}

function closeModal() { $('#demo-modal').hidden = true; }

function setupShell() {
  $$('[data-scroll]').forEach(button => button.addEventListener('click', event => {
    event.preventDefault();
    scrollToSection(button.dataset.scroll);
  }));
  $('#header-public').addEventListener('click', () => scrollToSection('transparencia'));
  $('#header-login').addEventListener('click', () => scrollToSection('acesso'));
  $('#menu-button').addEventListener('click', () => {
    const nav = $('#main-nav');
    const isOpen = nav.classList.toggle('open');
    $('#menu-button').setAttribute('aria-expanded', String(isOpen));
  });
  $('#accessibility-button').addEventListener('click', () => openModal('Acessibilidade', 'A nova versão usa foco visível, navegação por teclado, labels associados, mensagens semânticas e contraste conforme as orientações do Design System Gov.br.'));
  $('#modal-close').addEventListener('click', closeModal);
  $('#modal-ok').addEventListener('click', closeModal);
  $('.modal-scrim').addEventListener('click', closeModal);
  document.addEventListener('keydown', event => { if (event.key === 'Escape') closeModal(); });
}

function setupProfiles() {
  $$('input[name="profile"]').forEach(input => input.addEventListener('change', () => {
    selectedProfile = input.value;
    const profile = profiles[selectedProfile];
    $('#selected-profile-title').textContent = profile.title;
    $('#selected-profile-copy').textContent = profile.copy;
    $('#govbr-login').disabled = false;
  }));
  $('#govbr-login').addEventListener('click', () => {
    if (!selectedProfile) return;
    const profile = profiles[selectedProfile];
    $('#workspace').hidden = false;
    $('#workspace-role').textContent = `Perfil selecionado: ${profile.title}`;
    $('#workspace-scope').textContent = profile.scope;
    $('#workspace-title').textContent = `Área de trabalho · ${profile.title}`;
    $('#workspace-copy').textContent = profile.copy;
    $('#permission-list').innerHTML = profile.permissions.map(item => `<li>${item}</li>`).join('');
    $('#municipal-workspace').hidden = profile.workspace !== 'municipal';
    $('#readonly-workspace').hidden = profile.workspace === 'municipal';
    $('#readonly-title').textContent = `Visão de acompanhamento · ${profile.title}`;
    $('#readonly-copy').textContent = profile.copy;
    $('#workspace').scrollIntoView({ behavior: 'smooth', block: 'start' });
    openModal('Autenticação simulada', 'Na implementação, esta etapa redirecionará o usuário ao Login Único gov.br e retornará ao sistema com a identidade autenticada. O protótipo abriu a área de trabalho correspondente ao perfil escolhido.');
  });
  $('#back-public').addEventListener('click', () => { $('#workspace').hidden = true; scrollToSection('transparencia'); });
  $('#save-demo').addEventListener('click', () => openModal('Rascunho salvo', 'O protótipo não envia dados. Na versão integrada, o rascunho será persistido com usuário, município, versão do arquivo e trilha de auditoria.'));
  $('#submit-demo').addEventListener('click', () => openModal('Revisão necessária', 'Antes do envio, o sistema deve verificar o arquivo, a manifestação condicional e os campos obrigatórios.'));
  $('#export-role-data').addEventListener('click', () => openModal('Exportação controlada', 'A API deverá aplicar o mesmo escopo do perfil antes de gerar CSV, GeoJSON ou relatório.'));
}

function setupUpload() {
  $('#risk-file').addEventListener('change', event => {
    const files = [...event.target.files];
    $('#file-list').textContent = files.length ? files.map(file => `${file.name} · ${(file.size / 1024 / 1024).toFixed(2)} MB`).join(' | ') : '';
  });
  $('#download-demo').addEventListener('click', () => {
    const csv = '\ufeffcodigo_ibge,municipio,uf,situacao\n4314902,Porto Alegre,RS,Cadastrado\n3304557,Rio de Janeiro,RJ,Cadastrado\n3550308,São Paulo,SP,Cadastrado\n2611606,Recife,PE,Cadastrado\n1302603,Manaus,AM,Cadastrado\n';
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
    const link = document.createElement('a'); link.href = url; link.download = 'cadastro-nacional-recorte-demonstrativo.csv'; link.click(); URL.revokeObjectURL(url);
  });
}

function requestJson(url) {
  return fetch(url, { mode: 'cors' }).then(response => {
    if (!response.ok) throw new Error(`Resposta ${response.status} em ${url}`);
    return response.json();
  });
}

function featureCode(feature) { return String(feature?.properties?.codarea || feature?.properties?.CD_MUN || feature?.id || '').replace(/\.0$/, ''); }
function featureStatus(code) {
  if (registeredCodes.has(code)) return 'registered';
  if (inProgressCodes.has(code)) return 'in-progress';
  if (indicatedCodes.has(code)) return 'indicated';
  return 'other';
}
function statusLabel(status) { return { registered: 'Cadastrado · hachura vermelha', indicated: 'Indicado · poligonal vermelha', 'in-progress': 'Em preenchimento', other: 'Não indicado · contorno preto' }[status]; }

async function loadMapData() {
  if (mapDataPromise) return mapDataPromise;
  mapDataPromise = (async () => {
    const namesPromise = requestJson('https://servicodados.ibge.gov.br/api/v1/localidades/municipios');
    const municipalities = [];
    const states = [];
    for (let index = 0; index < stateCodes.length; index += 5) {
      const batch = stateCodes.slice(index, index + 5);
      const [municipalityResults, stateResults] = await Promise.all([
        Promise.all(batch.map(code => requestJson(`${geometryBase}/estados/${code}?formato=application/vnd.geo+json&resolucao=2&intrarregiao=municipio`))),
        Promise.all(batch.map(code => requestJson(`${geometryBase}/estados/${code}?formato=application/vnd.geo+json&resolucao=2`)))
      ]);
      municipalityResults.forEach(item => municipalities.push(...(item.features || [])));
      stateResults.forEach(item => states.push(...(item.features || [])));
    }
    const names = await namesPromise;
    const metadata = new Map((Array.isArray(names) ? names : []).map(item => [String(item.id), { name: item.nome, uf: item.microrregiao?.mesorregiao?.UF?.sigla || '' }]));
    return { municipalities, states, metadata };
  })();
  return mapDataPromise;
}

function mapStyle(feature, filter = 'all') {
  const status = featureStatus(featureCode(feature));
  const filtered = filter === 'indicated' ? !['indicated', 'registered'].includes(status) : filter === 'registered' ? status !== 'registered' : filter === 'other' ? status !== 'other' : false;
  if (filtered) return { color: '#aeb4ba', weight: .35, opacity: .5, fillColor: '#fff', fillOpacity: 0 };
  if (status === 'registered') return { color: '#991b1b', weight: 2.1, opacity: 1, fillColor: '#ffd8d4', fillOpacity: .5 };
  if (status === 'indicated') return { color: '#b42318', weight: 1.5, opacity: 1, fillColor: '#fff4f2', fillOpacity: .08 };
  if (status === 'in-progress') return { color: '#bd7520', weight: 1.6, opacity: 1, fillColor: '#fff6df', fillOpacity: .25 };
  return { color: '#111827', weight: .55, opacity: .72, fillColor: '#fff', fillOpacity: 0 };
}

function popupContent(feature, metadata) {
  const code = featureCode(feature);
  const item = metadata.get(code) || { name: `Município ${code}`, uf: '' };
  return `<div class="national-map-popup"><strong>${item.name}</strong><small>${item.uf} · IBGE ${code}</small><small>${statusLabel(featureStatus(code))}</small></div>`;
}

function installHatch(renderer) {
  const svg = renderer?._container;
  if (!svg || svg.querySelector('#govbr-red-hatch')) return;
  const defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');
  const pattern = document.createElementNS('http://www.w3.org/2000/svg', 'pattern');
  pattern.id = 'govbr-red-hatch'; pattern.setAttribute('width', '9'); pattern.setAttribute('height', '9'); pattern.setAttribute('patternUnits', 'userSpaceOnUse');
  const path = document.createElementNS('http://www.w3.org/2000/svg', 'path'); path.setAttribute('d', 'M-2,2 L2,-2 M0,9 L9,0 M7,11 L11,7'); path.setAttribute('stroke', '#b42318'); path.setAttribute('stroke-width', '1.35');
  pattern.append(path); defs.append(pattern); svg.insertBefore(defs, svg.firstChild);
}

function applyMapFilter(filter) {
  currentMapFilter = filter;
  $$('[data-map-filter]').forEach(button => button.classList.toggle('active', button.dataset.mapFilter === filter));
  if (!municipalLayer) return;
  municipalLayer.eachLayer(layer => layer.setStyle(mapStyle(layer.feature, filter)));
  if (registeredLayer) registeredLayer.setStyle({ opacity: filter === 'registered' || filter === 'all' || filter === 'other' ? 1 : 0, fillOpacity: filter === 'registered' || filter === 'all' ? .85 : 0 });
}

async function loadNationalMap() {
  const host = $('#national-map');
  if (!host || !window.L) return;
  const loading = document.createElement('div'); loading.className = 'national-map-loading'; loading.innerHTML = '<div><strong>Carregando poligonais oficiais</strong><small>Consultando a malha municipal e os limites estaduais do IBGE. A indicação técnica será desenhada em vermelho.</small></div>'; host.append(loading);
  nationalMap = L.map(host, { preferCanvas: true, minZoom: 3, maxZoom: 10, zoomControl: true, attributionControl: true }).setView([-14.2, -51.9], 4);
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19, opacity: .2, attribution: '&copy; OpenStreetMap · malha IBGE' }).addTo(nationalMap);
  try {
    const data = await loadMapData();
    municipalLayer = L.geoJSON({ type: 'FeatureCollection', features: data.municipalities }, { renderer: L.canvas({ padding: .35 }), style: feature => mapStyle(feature, currentMapFilter), onEachFeature: (feature, layer) => { layer.bindPopup(popupContent(feature, data.metadata)); layer.on({ mouseover: event => event.target.setStyle({ weight: Math.max(mapStyle(feature, currentMapFilter).weight + .5, 1.1) }), mouseout: event => event.target.setStyle(mapStyle(feature, currentMapFilter)) }); } }).addTo(nationalMap);
    stateLayer = L.geoJSON({ type: 'FeatureCollection', features: data.states }, { renderer: L.canvas({ padding: .35 }), style: { color: '#27364b', weight: 1.35, opacity: .76, fill: false, fillOpacity: 0 }, interactive: false }).addTo(nationalMap);
    const registeredFeatures = data.municipalities.filter(feature => registeredCodes.has(featureCode(feature)));
    const hatchRenderer = L.svg({ padding: .5 });
    registeredLayer = L.geoJSON({ type: 'FeatureCollection', features: registeredFeatures }, { renderer: hatchRenderer, style: { color: '#991b1b', weight: 2.1, opacity: 1, fillColor: 'url(#govbr-red-hatch)', fillOpacity: .85 }, onEachFeature: (feature, layer) => layer.bindPopup(popupContent(feature, data.metadata)) }).addTo(nationalMap);
    installHatch(hatchRenderer); applyMapFilter('all');
    const bounds = municipalLayer.getBounds(); if (bounds.isValid()) nationalMap.fitBounds(bounds, { padding: [16, 16], maxZoom: 5 });
    loading.remove(); nationalMap.invalidateSize();
  } catch (error) {
    loading.innerHTML = '<div><strong>A malha oficial não respondeu</strong><small>A lista pública continua disponível. Tente atualizar a página ou consulte a fonte IBGE diretamente.</small></div>';
    console.warn('Mapa nacional indisponível', error);
  }
}

function setupMapControls() { $$('[data-map-filter]').forEach(button => button.addEventListener('click', () => applyMapFilter(button.dataset.mapFilter))); }

document.addEventListener('DOMContentLoaded', () => { setupShell(); setupProfiles(); setupUpload(); setupMapControls(); loadNationalMap(); });
