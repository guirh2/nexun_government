/* iPad OS 2026 - Core System Logic 
   Features: Persistence, Dynamic App Loading (Iframes), Jiggle Mode
*/

// 1. DEFINIÇÃO DE APPS E ESTADO INICIAL
const defaultApps = [   
    { id: 'governo', label: 'Governo', icon: 'fas fa-landmark', color: 'bg-blue', isDock: false },
    { id: 'saude',   label: 'Secretaria de Saude', icon: 'fa-sharp fa-solid fa-briefcase-medical', color: 'bg-red', isDock: false },
    { id: 'settings', label: 'Ajustes', icon: 'fas fa-cog', color: 'bg-agrey', isDock: true }
];

// Carregar apps salvos ou usar padrão
let allApps = JSON.parse(localStorage.getItem('ipad-apps-pos')) || defaultApps;
let isEditing = false;
let dragSrcId = null;
let pressTimer;

// Caminhos locais para wallpapers
const localWallpapers = ['assets/bg1.png', 'assets/bg2.png', 'assets/bg3.png'];

// 2. INICIALIZAÇÃO DO SISTEMA
document.addEventListener('DOMContentLoaded', () => {
    loadWallpaper();
    renderSystem();
    initClock();
    
    // Fechar modo edição ao clicar no fundo (vazio)
    document.getElementById('ipad-screen').addEventListener('click', (e) => {
        if ((e.target.id === 'ipad-screen' || e.target.id === 'app-grid') && isEditing) {
            stopEditing();
        }
    });

    // Home Indicator Logic
    document.querySelector('.home-indicator').addEventListener('click', (e) => {
        e.stopPropagation();
        if (isEditing) {
            stopEditing();
        } else {
            closeApp();
        }
    });
});

// 3. RENDERIZAÇÃO DA INTERFACE
function renderSystem() {
    const grid = document.getElementById('app-grid');
    const dock = document.getElementById('dock-container');
    grid.innerHTML = ''; 
    dock.innerHTML = '';

    allApps.forEach(app => {
        const item = document.createElement('div');
        item.setAttribute('data-id', app.id);
        item.setAttribute('draggable', isEditing ? 'true' : 'false');
        
        // Handlers de Drag & Drop
        item.ondragstart = (e) => { dragSrcId = app.id; e.target.classList.add('dragging'); };
        item.ondragover = (e) => { e.preventDefault(); e.currentTarget.classList.add('drag-over'); };
        item.ondragleave = (e) => e.currentTarget.classList.remove('drag-over');
        item.ondrop = handleDrop;

        // Clique e Long Press para Jiggle Mode
        item.onclick = (e) => { e.stopPropagation(); if (!isEditing) openApp(app.id); };
        item.onmousedown = () => pressTimer = setTimeout(() => startEditing(), 800);
        item.onmouseup = () => clearTimeout(pressTimer);
        item.ontouchstart = () => pressTimer = setTimeout(() => startEditing(), 800);
        item.ontouchend = () => clearTimeout(pressTimer);

        if (app.isDock) {
            item.className = `dock-icon ${app.color}`;
            item.innerHTML = `<i class="${app.icon}"></i>`;
            dock.appendChild(item);
        } else {
            item.className = 'app-item';
            item.innerHTML = `
                <div class="icon-box ${app.color}"><i class="${app.icon}"></i></div>
                <span>${app.label}</span>
            `;
            grid.appendChild(item);
        }
    });

    document.body.classList.toggle('editing', isEditing);
}

// 4. LÓGICA DE MOVIMENTAÇÃO (DRAG & DROP)
function handleDrop(e) {
    e.preventDefault();
    const targetId = e.currentTarget.getAttribute('data-id');
    if (dragSrcId === targetId) return;

    const sourceIdx = allApps.findIndex(a => a.id === dragSrcId);
    const targetIdx = allApps.findIndex(a => a.id === targetId);

    // Swap no array
    const temp = allApps[sourceIdx];
    allApps[sourceIdx] = allApps[targetIdx];
    allApps[targetIdx] = temp;

    // Preservar quem é Dock e quem é Grid
    const sourceWasDock = allApps[sourceIdx].isDock;
    allApps[sourceIdx].isDock = allApps[targetIdx].isDock;
    allApps[targetIdx].isDock = sourceWasDock;

    saveAppState();
    renderSystem();
}

function startEditing() { isEditing = true; renderSystem(); }
function stopEditing() { isEditing = false; renderSystem(); }
function saveAppState() { localStorage.setItem('ipad-apps-pos', JSON.stringify(allApps)); }

// 5. MOTOR DE APLICAÇÕES (ABRIR / FECHAR)
function openApp(id) {
    const app = allApps.find(a => a.id === id);
    const content = document.getElementById('app-content-area');
    const win = document.getElementById('app-window');
    
    document.getElementById('active-app-title').innerText = app.label;
    win.classList.remove('hidden');

    // Lógica por ID de Aplicativo
// Dentro da função openApp(id) no seu script.js:
if (id === 'governo') {
    content.innerHTML = `
        <iframe src="apps/governo/governo.html" 
                style="width:100%; height:100%; border:none; display:block; overflow:auto;">
        </iframe>`;
}else if (id === 'saude') {
        content.innerHTML = `
            <iframe src="apps/saude/saude.html" 
                    style="width:100%; height:100%; border:none; display:block; overflow:auto;">
            </iframe>`;
    }
    else if (id === 'settings') {
        renderSettingsPage(content);
    } 
    else {
        content.innerHTML = `
            <div style="display:flex; justify-content:center; align-items:center; height:100%; color:#8e8e93; flex-direction:column;">
                <i class="${app.icon}" style="font-size:100px; opacity:0.1; margin-bottom:20px;"></i>
                <p>Módulo ${app.label} em desenvolvimento.</p>
            </div>`;
    }
}



function closeApp() {
    document.getElementById('app-window').classList.add('hidden');
    document.getElementById('app-content-area').innerHTML = ''; // Limpar iframe ao fechar
}

// 6. PÁGINA DE AJUSTES INTERNA
function renderSettingsPage(container) {
    container.innerHTML = `
        <div style="padding:35px; color:#1c1c1e;">
            <h2 style="font-size:28px; margin-bottom:10px;">Ajustes</h2>
            <p style="opacity:0.6; margin-bottom:30px;">Personalização do Sistema</p>
            
            <h4 style="text-transform:uppercase; font-size:12px; opacity:0.5; letter-spacing:1px;">Wallpapers</h4>
            <div style="display:flex; gap:15px; margin-top:15px;">
                ${localWallpapers.map(path => `
                    <div onclick="updateWallpaper('${path}')" 
                         style="width:100px; height:150px; border-radius:12px; background-image:url('${path}'); 
                         background-size:cover; cursor:pointer; border:3px solid #fff; box-shadow:0 10px 20px rgba(0,0,0,0.15);">
                    </div>
                `).join('')}
            </div>
            
            <div style="margin-top:50px; border-top:1px solid rgba(0,0,0,0.05); padding-top:20px;">
                <button onclick="resetSystem()" style="color:#ff3b30; border:none; background:none; font-weight:600; cursor:pointer; font-size:15px;">
                    <i class="fas fa-redo-alt" style="margin-right:8px;"></i> Resetar Layout e Cache
                </button>
            </div>
        </div>
    `;
}

function updateWallpaper(url) {
    document.getElementById('ipad-screen').style.backgroundImage = `url('${url}')`;
    localStorage.setItem('ipad-wallpaper', url);
}

function loadWallpaper() {
    const saved = localStorage.getItem('ipad-wallpaper') || 'assets/bg1.png';
    document.getElementById('ipad-screen').style.backgroundImage = `url('${saved}')`;
}

function resetSystem() {
    if(confirm("Deseja resetar todas as configurações de layout e wallpaper?")) {
        localStorage.clear();
        location.reload();
    }
}

// 7. RELÓGIO E DATA
function initClock() {
    const update = () => {
        const now = new Date();
        document.getElementById('ios-time').innerText = now.toLocaleTimeString('pt-PT', { hour: '2-digit', minute: '2-digit' });
        document.getElementById('ios-date').innerText = now.toLocaleDateString('pt-PT', { weekday: 'long', day: 'numeric', month: 'long' });
    };
    update();
    setInterval(update, 1000);
}

