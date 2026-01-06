/**
 * SISTEMA DE GOVERNO - DADOS 100% REAIS DO BANCO
 * SEM DADOS SIMULADOS - CONEXÃO DIRETA COM FIVEM
 * Versão: 3.0.0
 */

// ====================
// CONFIGURAÇÃO DO AMBIENTE
// ====================

// Detectar ambiente FiveM NUI
const IS_FIVEM_NUI = (() => {
    try {
        // Verificar funções exclusivas do FiveM
        const hasNUI = typeof GetParentResourceName !== 'undefined';
        const hasSendNUIMessage = typeof SendNUIMessage !== 'undefined';
        
        if (hasNUI && hasSendNUIMessage) {
            console.log('[GOV] Ambiente: FiveM NUI detectado');
            return true;
        } else {
            console.warn('[GOV] Ambiente: NÃO está no FiveM');
            return false;
        }
    } catch (e) {
        console.error('[GOV] Erro ao detectar ambiente:', e);
        return false;
    }
})();

// Nome do resource
const RESOURCE_NAME = IS_FIVEM_NUI ? GetParentResourceName() : null;

console.log(`[GOV] Sistema inicializado`);
console.log(`[GOV] FiveM NUI: ${IS_FIVEM_NUI}`);
console.log(`[GOV] Resource: ${RESOURCE_NAME || 'N/A'}`);

// Estado da aplicação
const AppState = {
    currentTab: 'dash',
    userData: null,
    isLoading: false,
    lastUpdate: null
};

// ====================
// SISTEMA DE COMUNICAÇÃO REAL
// ====================

/**
 * Chamar servidor Lua - VERSÃO REAL SEM MOCK
 */
async function callServer(action, data = {}) {
    return new Promise((resolve, reject) => {
        // VERIFICAÇÃO CRÍTICA: Só funciona dentro do FiveM
        if (!IS_FIVEM_NUI) {
            const error = 'ERRO: Sistema só funciona dentro do FiveM';
            console.error(`[GOV-API] ${error}`);
            reject(new Error(error));
            return;
        }

        console.log(`[GOV-API] Enviando para Lua: ${action}`, data);

        // REQUISIÇÃO REAL PARA O LUA
        fetch(`https://${RESOURCE_NAME}/${action}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        })
        .then(response => {
            console.log(`[GOV-API] Status: ${response.status}`);
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            
            return response.json();
        })
        .then(responseData => {
            console.log(`[GOV-API] Resposta recebida para ${action}:`, responseData);
            
            if (!responseData) {
                throw new Error('Resposta vazia do servidor');
            }
            
            resolve(responseData);
        })
        .catch(error => {
            console.error(`[GOV-API] ERRO em ${action}:`, error);
            
            // Mostrar erro específico para o usuário
            let errorMessage = `Falha na comunicação com o servidor`;
            
            if (error.message.includes('Failed to fetch')) {
                errorMessage = 'Servidor Lua não respondeu. Verifique se o resource está carregado.';
            } else if (error.message.includes('HTTP')) {
                errorMessage = `Erro ${error.message}`;
            }
            
            showNotification(errorMessage, 'error');
            reject(error);
        });
    });
}

// ====================
// 1. NAVEGAÇÃO ENTRE ABAS
// ====================

function showTab(tabId, element) {
    console.log(`[GOV] Abrindo aba: ${tabId}`);
    
    // Remover classe ativa
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
    });
    
    // Ativar nova aba
    const targetTab = document.getElementById(tabId);
    if (targetTab) {
        targetTab.classList.add('active');
    }
    
    if (element) {
        element.classList.add('active');
    }
    
    AppState.currentTab = tabId;
    
    // Carregar dados da aba
    switch(tabId) {
        case 'dash':
            loadDashboardData();
            break;
        case 'tesouraria':
            loadTreasuryData();
            break;
        case 'legislacao':
            loadLawsData();
            break;
        case 'membros':
            loadMembersData();
            break;
        case 'emendas':
            loadAmendmentsData();
            break;
        case 'demandas':
            loadRequestsData();
            break;
    }
}

// ====================
// 2. NOTIFICAÇÕES
// ====================

function showNotification(message, type = 'info') {
    console.log(`[NOTIFICAÇÃO ${type.toUpperCase()}] ${message}`);
    
    const container = document.getElementById('toast-container');
    if (!container) {
        console.warn('[GOV] Container de notificações não encontrado');
        return;
    }
    
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    
    // Ícones por tipo
    const icons = {
        success: '✓',
        error: '✗',
        warning: '⚠',
        info: 'ℹ'
    };
    
    toast.innerHTML = `
        <span style="font-weight: bold; font-size: 16px;">${icons[type] || 'ℹ'}</span>
        <span style="flex: 1; font-size: 13px;">${message}</span>
    `;
    
    container.appendChild(toast);
    
    // Animação
    setTimeout(() => toast.style.opacity = '1', 10);
    
    // Remover após 4s
    setTimeout(() => {
        toast.style.opacity = '0';
        setTimeout(() => toast.remove(), 300);
    }, 4000);
}

// ====================
// 3. DASHBOARD - DADOS REAIS DO BANCO
// ====================

async function loadDashboardData() {
    if (AppState.isLoading) return;
    
    console.log('[DASHBOARD] Buscando dados REAIS do banco...');
    AppState.isLoading = true;
    
    try {
        // CHAMADA REAL PARA O SERVIDOR
        const data = await callServer('getDashboardData');
        
        if (!data) {
            throw new Error('Nenhum dado recebido do servidor');
        }
        
        console.log('[DASHBOARD] Dados recebidos:', data);
        updateDashboardUI(data);
        AppState.lastUpdate = new Date();
        
    } catch (error) {
        console.error('[DASHBOARD] ERRO:', error);
        showNotification('Não foi possível carregar os dados do dashboard', 'error');
    } finally {
        AppState.isLoading = false;
    }
}

function updateDashboardUI(data) {
    console.log('[DASHBOARD] Atualizando interface com dados REAIS');
    
    // 1. SALDO DO TESOURO (DO BANCO)
    const saldoElement = document.getElementById('saldo-tesouro');
    if (saldoElement && data.treasuryBalance !== undefined) {
        saldoElement.textContent = 'R$ ' + formatNumber(data.treasuryBalance);
        console.log(`[DASHBOARD] Saldo atualizado: R$ ${data.treasuryBalance}`);
    }
    
    // 2. ARRECADAÇÃO TOTAL (DO BANCO)
    const arrecadacaoElement = document.getElementById('arrecadacao-total');
    if (arrecadacaoElement && data.totalRevenue !== undefined) {
        arrecadacaoElement.textContent = 'R$ ' + formatNumber(data.totalRevenue);
    }
    
    // 3. SERVIDORES ATIVOS (DO BANCO)
    const servidoresElement = document.getElementById('servidores-ativos');
    if (servidoresElement && data.activeEmployees !== undefined) {
        servidoresElement.textContent = data.activeEmployees;
    }
    
    // 4. IMPOSTOS (DO BANCO)
    if (data.taxRates) {
        updateTaxRates(data.taxRates);
    }
    
    // 5. ATIVIDADES (DO BANCO)
    if (data.recentActivities) {
        updateRecentActivities(data.recentActivities);
    }
    
    // 6. TIMESTAMP DA ATUALIZAÇÃO
    const agora = new Date();
    const hora = agora.getHours().toString().padStart(2, '0');
    const minutos = agora.getMinutes().toString().padStart(2, '0');
    
    const timestampElement = document.getElementById('ultima-atualizacao');
    if (timestampElement) {
        timestampElement.textContent = `${hora}:${minutos}`;
    }
    
    showNotification('Dashboard atualizado com dados reais', 'success');
}

function updateTaxRates(taxRates) {
    console.log('[DASHBOARD] Atualizando impostos:', taxRates);
    
    // Mapeamento dos impostos
    const taxElements = {
        'iptu': 'valor-iptu',
        'ipva': 'valor-ipva', 
        'inss': 'valor-inss',
        'fuel': 'valor-fuel',
        'business': 'valor-business',
        'iss': 'valor-iss',
        'iof': 'valor-iof',
        'icms': 'valor-icms'
    };
    
    // Atualizar cada imposto
    Object.entries(taxElements).forEach(([taxKey, elementId]) => {
        const element = document.getElementById(elementId);
        if (element && taxRates[taxKey] !== undefined) {
            const value = taxRates[taxKey];
            element.textContent = value.toFixed(2) + '%';
        }
    });
    
    // Licença (valor fixo)
    const licencaElement = document.getElementById('valor-licenca');
    if (licencaElement) {
        licencaElement.textContent = 'R$ 500';
    }
}

function updateRecentActivities(activities) {
    const container = document.getElementById('atividades-recentes');
    if (!container) return;
    
    container.innerHTML = '';
    
    if (!activities || activities.length === 0) {
        container.innerHTML = `
            <div style="text-align: center; padding: 20px; color: var(--text-muted);">
                <i class="fas fa-inbox"></i>
                <p>Nenhuma atividade recente</p>
            </div>
        `;
        return;
    }
    
    activities.forEach(activity => {
        const div = document.createElement('div');
        div.style.cssText = `
            padding: 10px;
            border-bottom: 1px solid var(--border-color);
            font-size: 13px;
        `;
        
        div.innerHTML = `
            <strong style="color: var(--accent-blue);">${activity.date || ''}</strong>
            <div>${activity.description || activity.title || ''}</div>
        `;
        
        container.appendChild(div);
    });
}

// ====================
// 4. TESOURARIA - SISTEMA REAL
// ====================

async function loadTreasuryData() {
    console.log('[TESOURARIA] Carregando dados financeiros REAIS...');
    
    try {
        const data = await callServer('getTreasuryData');
        
        if (data) {
            updateTreasuryUI(data);
        }
    } catch (error) {
        console.error('[TESOURARIA] ERRO:', error);
        showNotification('Erro ao carregar tesouraria', 'error');
    }
}

function updateTreasuryUI(data) {
    console.log('[TESOURARIA] Atualizando com dados:', data);
    
    // Saldo atual
    if (data.balance !== undefined) {
        const saldoElement = document.getElementById('saldo-atual');
        if (saldoElement) {
            saldoElement.textContent = 'R$ ' + formatNumber(data.balance);
        }
    }
    
    // Histórico
    if (data.history && Array.isArray(data.history)) {
        updateTransactionHistory(data.history);
    }
}

function updateTransactionHistory(transactions) {
    const container = document.getElementById('historico-financeiro');
    if (!container) return;
    
    container.innerHTML = '';
    
    if (transactions.length === 0) {
        container.innerHTML = `
            <div class="mini-box" style="text-align: center; padding: 20px;">
                <p style="color: var(--text-muted);">Nenhuma transação registrada</p>
            </div>
        `;
        return;
    }
    
    transactions.forEach(trans => {
        const div = document.createElement('div');
        div.className = 'mini-box';
        
        const isSaida = trans.from_account === 'state';
        
        div.innerHTML = `
            <div style="display: flex; justify-content: space-between;">
                <div>
                    <strong>${trans.description || 'Transação'}</strong><br>
                    <small style="color: var(--text-muted);">${trans.date || ''}</small>
                </div>
                <div style="text-align: right;">
                    <span style="color: ${isSaida ? '#ff3b30' : '#34c759'}; font-weight: 700;">
                        ${isSaida ? '-' : '+'} R$ ${formatNumber(trans.amount || 0)}
                    </span><br>
                    <small style="color: var(--text-muted);">${trans.transaction_type || ''}</small>
                </div>
            </div>
        `;
        
        container.appendChild(div);
    });
}

// FUNÇÃO DE TRANSFERÊNCIA REAL
async function executarTransferencia() {
    console.log('[TRANSFERÊNCIA] Iniciando...');
    
    const destino = document.getElementById('transf-destino');
    const valorInput = document.getElementById('transf-valor');
    const motivo = document.getElementById('transf-motivo');
    
    if (!destino || !valorInput || !motivo) {
        showNotification('Complete todos os campos', 'error');
        return;
    }
    
    const destinoVal = destino.value;
    const valor = parseFloat(valorInput.value);
    const motivoVal = motivo.value.trim();
    
    if (!destinoVal || isNaN(valor) || valor <= 0 || !motivoVal) {
        showNotification('Dados inválidos', 'error');
        return;
    }
    
    try {
        showNotification('Processando transferência...', 'info');
        
        const result = await callServer('transferFunds', {
            destination: destinoVal,
            amount: valor,
            reason: motivoVal
        });
        
        if (result && result.success !== false) {
            showNotification(`Transferência de R$ ${formatNumber(valor)} realizada!`, 'success');
            
            // Limpar campos
            valorInput.value = '';
            motivo.value = '';
            
            // Recarregar dados
            setTimeout(() => {
                loadTreasuryData();
                if (AppState.currentTab === 'dash') {
                    loadDashboardData();
                }
            }, 2000);
        }
    } catch (error) {
        console.error('[TRANSFERÊNCIA] ERRO:', error);
    }
}

// ====================
// 5. LEGISLAÇÃO - SISTEMA REAL
// ====================

async function loadLawsData() {
    try {
        const data = await callServer('getLawsData');
        if (data) updateLawsUI(data);
    } catch (error) {
        console.error('[LEGISLAÇÃO] ERRO:', error);
    }
}

// ====================
// 6. MEMBROS - SISTEMA REAL
// ====================

async function loadMembersData() {
    try {
        const data = await callServer('getMembersData');
        if (data) updateMembersUI(data);
    } catch (error) {
        console.error('[MEMBROS] ERRO:', error);
    }
}

function updateMembersUI(data) {
    // Contagem de membros
    if (data.gradeCounts) {
        const containers = document.querySelectorAll('.stat-box-membro h2');
        if (containers.length >= 5) {
            containers[0].textContent = data.gradeCounts.secretario || 0;
            containers[1].textContent = data.gradeCounts.secretario || 0;
            containers[2].textContent = data.gradeCounts.secretario || 0;
            containers[3].textContent = data.gradeCounts.vice || 0;
            containers[4].textContent = data.gradeCounts.governador || 0;
        }
    }
    
    // Lista de membros online
    if (data.onlineMembers && Array.isArray(data.onlineMembers)) {
        updateOnlineMembers(data.onlineMembers);
    }
}

function updateOnlineMembers(members) {
    const container = document.getElementById('membersList');
    if (!container) return;
    
    container.innerHTML = '';
    
    members.forEach(member => {
        const div = document.createElement('div');
        div.className = 'member-card';
        
        div.innerHTML = `
            <div style="display: flex; align-items: center; gap: 15px;">
                <div style="width:45px; height:45px; border-radius:50%; background:#007aff; 
                     display:flex; align-items:center; justify-content:center; color:white;">
                    <i class="fas fa-user"></i>
                </div>
                <div>
                    <b>${member.name}</b><br>
                    <small style="color:#8e8e93;">ID: ${member.citizenid || 'N/A'}</small>
                </div>
            </div>
            <div style="text-align:right;">
                <span style="background:#007aff; color:white; padding:4px 12px; 
                     border-radius:10px; font-size:11px; font-weight:700;">
                    ${member.grade || 'Membro'}
                </span>
                <span style="display:block; font-size:10px; color:#8e8e93; margin-top:5px;">
                    Online
                </span>
            </div>
        `;
        
        container.appendChild(div);
    });
}

// ====================
// 7. EMENDAS - SISTEMA REAL
// ====================

async function loadAmendmentsData() {
    try {
        const data = await callServer('getAmendmentsData');
        if (data) updateAmendmentsUI(data);
    } catch (error) {
        console.error('[EMENDAS] ERRO:', error);
    }
}

// ====================
// 8. DEMANDAS - SISTEMA REAL
// ====================

async function loadRequestsData() {
    try {
        const data = await callServer('getRequestsData');
        if (data) updateRequestsUI(data);
    } catch (error) {
        console.error('[DEMANDAS] ERRO:', error);
    }
}

// ====================
// 9. UTILITÁRIOS
// ====================

function formatNumber(num) {
    if (num === undefined || num === null) return "0,00";
    const n = parseFloat(num);
    if (isNaN(n)) return "0,00";
    
    return n.toLocaleString('pt-BR', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    });
}

// ====================
// 10. INICIALIZAÇÃO E NUI
// ====================

document.addEventListener('DOMContentLoaded', function() {
    console.log('[GOV] DOM carregado, configurando sistema...');
    
    // Configurar botão de transferência
    const transferBtn = document.getElementById('btn-transferir');
    if (transferBtn) {
        transferBtn.addEventListener('click', executarTransferencia);
        console.log('[GOV] Botão de transferência configurado');
    }
    
    // Configurar modais
    window.addEventListener('click', function(event) {
        const modals = ['modalNomear', 'modalLei', 'modalEmenda', 'modalDemanda'];
        modals.forEach(modalId => {
            const modal = document.getElementById(modalId);
            if (modal && event.target === modal) {
                modal.style.display = 'none';
            }
        });
    });
    
    // Configurar ESC
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            const modals = ['modalNomear', 'modalLei', 'modalEmenda', 'modalDemanda'];
            modals.forEach(modalId => {
                const modal = document.getElementById(modalId);
                if (modal && modal.style.display === 'flex') {
                    modal.style.display = 'none';
                }
            });
        }
    });
    
    // Carregar dados iniciais
    if (document.getElementById('dash').classList.contains('active')) {
        setTimeout(loadDashboardData, 1000);
    }
});

// ====================
// 11. COMUNICAÇÃO COM O LUA - CORRIGIDA
// ====================

if (IS_FIVEM_NUI) {
    // ESCUTAR MENSAGENS DO LUA
    window.addEventListener('message', function(event) {
        console.log('[GOV-NUI] Mensagem recebida do Lua:', event.data);
        
        if (event.data && event.data.action) {
            switch(event.data.action) {
                case 'openTablet':
                    // CORREÇÃO DO BUG: Atualizar nome do governador
                    if (event.data.data) {
                        AppState.userData = event.data.data;
                        
                        // CORREÇÃO AQUI: Usar seletores corretos
                        const nameElement = document.querySelector('.user-profile > div:first-child');
                        const roleElement = document.querySelector('.user-profile > div:last-child');
                        
                        if (nameElement) {
                            nameElement.textContent = event.data.data.playerName || 'Usuário';
                            console.log('[GOV-NUI] Nome atualizado:', event.data.data.playerName);
                        }
                        
                        if (roleElement) {
                            roleElement.textContent = event.data.data.playerJobGrade || 'Cargo';
                            console.log('[GOV-NUI] Cargo atualizado:', event.data.data.playerJobGrade);
                        }
                        
                        // Carregar dashboard
                        setTimeout(() => {
                            if (AppState.currentTab === 'dash') {
                                loadDashboardData();
                            }
                        }, 500);
                    }
                    break;
                    
                case 'updateData':
                    // Atualizar dados específicos
                    if (event.data.type === 'dashboard' && event.data.data) {
                        updateDashboardUI(event.data.data);
                    }
                    break;
                    
                case 'notification':
                    // Notificação do Lua
                    if (event.data.message) {
                        showNotification(event.data.message, event.data.type || 'info');
                    }
                    break;
            }
        }
    });
    
    // Informar que o JavaScript está pronto
    console.log('[GOV] Sistema JavaScript pronto para comunicação com Lua');
    
} else {
    console.warn('[GOV] Sistema carregado fora do FiveM - funcionalidades limitadas');
    
    // Placeholder para desenvolvimento
    setTimeout(() => {
        const nameEl = document.querySelector('.user-profile > div:first-child');
        const roleEl = document.querySelector('.user-profile > div:last-child');
        
        if (nameEl) nameEl.textContent = 'SISTEMA OFFLINE';
        if (roleEl) roleEl.textContent = 'Conecte ao FiveM';
        
        showNotification('Conecte ao FiveM para dados reais', 'warning');
    }, 1000);
}

console.log('[GOV] Sistema JavaScript completamente carregado');