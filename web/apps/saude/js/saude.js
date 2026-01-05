/**
 * SESAU - Gestão Estratégica e Logística
 * Sistema de Protocolos de Aquisição e Frota
 */

const AppSESAU = {
    modeloSelecionado: '',

    init() {
        this.bindNavigation();
        this.bindModalEvents();
        console.log("Gabinete SESAU: Sistema de Protocolos Ativo.");
    },

    // 1. Controle de Navegação (Dashboard / Frota / Equipe)
    bindNavigation() {
        const navItems = document.querySelectorAll('.nav-item');
        const tabs = document.querySelectorAll('.tab-view');
        const pageTitle = document.getElementById('page-title');
        const breadPath = document.getElementById('bread-path');

        navItems.forEach(item => {
            item.addEventListener('click', () => {
                const page = item.getAttribute('data-page');
                
                // Estilo do Menu
                navItems.forEach(i => i.classList.remove('active'));
                item.classList.add('active');

                // Troca de Telas
                tabs.forEach(tab => tab.classList.remove('active'));
                const targetTab = document.getElementById(`view-${page}`);
                if (targetTab) targetTab.classList.add('active');

                // Atualização de Cabeçalho (Dashboard nunca muda o ID, apenas o texto)
                if(page === 'dashboard') {
                    pageTitle.innerText = "Painel de Controle Financeiro e Ativos";
                    breadPath.innerText = "Administração / Executivo";
                } else if (page === 'frota') {
                    pageTitle.innerText = "Departamento de Logística e Frota";
                    breadPath.innerText = "Administração / Frota";
                }
            });
        });
    },

    // 2. Lógica do Modal de Protocolo
    bindModalEvents() {
        // Fechar modal ao clicar fora dele
        const modal = document.getElementById('modal-protocolo');
        window.onclick = (event) => {
            if (event.target == modal) this.fecharModal();
        };
    },

    // Chamada pelo botão "SOLICITAR" no HTML
    abrirProtocolo(modelo) {
        this.modeloSelecionado = modelo;
        const modal = document.getElementById('modal-protocolo');
        const txtVeiculo = document.getElementById('nome-veiculo-modal');

        const nomes = {
            'moto': 'Motolância de Resposta Rápida',
            'uti': 'Ambulância UTI Móvel (Alfa)',
            'heli': 'Helicóptero de Resgate Águia',
            'carro': 'VTR Administrativa / Apoio'
        };

        if (txtVeiculo) txtVeiculo.innerText = nomes[modelo] || modelo;
        if (modal) modal.style.display = 'flex';
    },

    fecharModal() {
        const modal = document.getElementById('modal-protocolo');
        if (modal) modal.style.display = 'none';
    },

    // Chamada pelo botão "ABRIR PROTOCOLO" dentro do Modal
    confirmarProtocolo() {
        const unidade = document.getElementById('unidade-destino').value;
        const prioridade = document.getElementById('prioridade-missao').value;

        // Estrutura de dados para o servidor/tablet do Diretor
        const dadosProtocolo = {
            veiculo: this.modeloSelecionado,
            destino: unidade,
            urgencia: prioridade,
            timestamp: new Date().getTime()
        };

        console.log("Gerando Protocolo para Diretoria:", dadosProtocolo);

        // INTEGRAÇÃO COM O SERVIDOR (NUI CALLBACK)
        /*
        fetch(`https://${GetParentResourceName()}/gerarProtocolo`, {
            method: 'POST',
            body: JSON.stringify(dadosProtocolo)
        });
        */

        alert(`SUCESSO!\nProtocolo enviado para o Diretor da unidade: ${unidade.toUpperCase()}.\nAguarde a designação de um funcionário para a missão.`);
        
        this.fecharModal();
    },

    // Função para dar baixa em veículos existentes
    darBaixa(placa) {
        const motivo = prompt(`Informe o motivo da baixa para a viatura ${placa}:`);
        if (motivo) {
            if (confirm(`Confirmar remoção permanente da viatura ${placa}?`)) {
                alert(`Viatura ${placa} baixada por: ${motivo}`);
                // Lógica para atualizar a tabela via NUI aqui
            }
        }
    }
};

// Iniciar app quando carregar o DOM
document.addEventListener('DOMContentLoaded', () => AppSESAU.init());

// Funções globais para os onclicks do HTML
window.abrirProtocolo = (m) => AppSESAU.abrirProtocolo(m);
window.fecharModal = () => AppSESAU.fecharModal();
window.confirmarProtocolo = () => AppSESAU.confirmarProtocolo();
window.darBaixa = (p) => AppSESAU.darBaixa(p);


// Forçar as funções para o escopo Global (window)
window.cargoSelecionado = "";

// 1. Função para abrir o modal salvando qual cargo foi clicado
window.abrirNomeacao = function(cargo) {
    window.cargoSelecionado = cargo; // Salva o cargo (ex: 'operacoes')
    const modal = document.getElementById('modal-appointment');
    if (modal) modal.style.display = 'flex';
};

// 2. Função para fechar o modal
window.fecharModal = function() {
    const modal = document.getElementById('modal-appointment');
    if (modal) modal.style.display = 'none';
    document.getElementById('target-id').value = '';
};

// 3. Lógica de Confirmação (Funciona para os 4 simultaneamente)
document.getElementById('btn-confirm-nomination').onclick = function() {
    const idPlayer = document.getElementById('target-id').value;
    const cargo = window.cargoSelecionado; // Recupera o cargo que salvamos no passo 1

    if (idPlayer && idPlayer > 0 && cargo) {
        // Notificação de sucesso
        if (window.showGovNotification) {
            window.showGovNotification("success", "NOMEAÇÃO CONCLUÍDA", `O ID ${idPlayer} agora é responsável pelo setor.`);
        }

        // Atualiza os elementos do HTML usando o ID do cargo
        const nomeElem = document.getElementById(`nome-${cargo}`);
        const statusElem = document.getElementById(`status-${cargo}`);
        const cardElem = document.getElementById(`card-${cargo}`);

        if (nomeElem) nomeElem.innerText = "ID: " + idPlayer;
        if (statusElem) {
            statusElem.className = "tag-ok";
            statusElem.innerText = "PUBLICADO";
        }
        if (cardElem) cardElem.classList.remove('highlight-vacant');

        window.fecharModal();
    } else {
        alert("Por favor, insira um ID válido.");
    }
};
// Lógica de Confirmação
document.addEventListener('DOMContentLoaded', function() {
    const btnConfirmar = document.getElementById('btn-confirm-nomination');

    if (btnConfirmar) {
// ATUALIZAÇÃO: Lógica para nomear qualquer um dos 4 cargos
btnConfirmar.onclick = function() {
    const idPlayer = document.getElementById('target-id').value;
    const cargo = window.cargoSelecionado; // Definido na função abrirNomeacao

    if (idPlayer && idPlayer > 0) {
        window.fecharModal();
        
        // Notificação de Sucesso
        window.showGovNotification("success", "Publicação Efetuada", `ID ${idPlayer} foi nomeado.`);

        // Atualiza dinamicamente o card baseado no cargo
        const nomeElem = document.getElementById(`nome-${cargo}`);
        const statusElem = document.getElementById(`status-${cargo}`);
        const cardElem = document.getElementById(`card-${cargo}`);

        if (nomeElem) nomeElem.innerText = "ID: " + idPlayer;
        if (statusElem) {
            statusElem.className = "tag-ok";
            statusElem.innerText = "PUBLICADO";
        }
        if (cardElem) cardElem.classList.remove('highlight-vacant');

    } else {
        window.showGovNotification("error", "Erro", "ID inválido.");
    }
};
    }
});

// Função Global para criar Notificações
window.showGovNotification = function(tipo, titulo, mensagem) {
    const container = document.getElementById('notification-container');
    if (!container) return;

    // Cria o elemento do toast
    const toast = document.createElement('div');
    toast.className = `gov-toast ${tipo}`; // tipo pode ser 'success' ou 'error'
    
    // Define o ícone baseado no tipo
    const icone = tipo === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle';

    toast.innerHTML = `
        <i class="fas ${icone}"></i>
        <div class="toast-content">
            <b>${titulo}</b>
            <span>${mensagem}</span>
        </div>
    `;

    container.appendChild(toast);

    // Remove automaticamente após 5 segundos
    setTimeout(() => {
        toast.classList.add('toast-fade-out');
        setTimeout(() => toast.remove(), 300);
    }, 5000);
};

// ATUALIZAÇÃO: Ajuste na lógica de clique do botão confirmar
document.addEventListener('DOMContentLoaded', function() {
    const btnConfirmar = document.getElementById('btn-confirm-nomination');

    if (btnConfirmar) {
// Localize onde está o btnConfirmar.onclick e substitua por este:
btnConfirmar.onclick = function() {
    const idPlayer = document.getElementById('target-id').value;
    const cargo = window.cargoSelecionado;

    if (idPlayer && idPlayer > 0 && cargo) {
        window.fecharModal();
        
        window.showGovNotification("success", "Publicação Efetuada", `ID ${idPlayer} foi nomeado.`);

        // Esta linha é o segredo: ela usa o ID do cargo clicado
        const nomeElem = document.getElementById(`nome-${cargo}`);
        const statusElem = document.getElementById(`status-${cargo}`);
        const cardElem = document.getElementById(`card-${cargo}`);

        if (nomeElem) {
            nomeElem.innerText = "ID: " + idPlayer;
            nomeElem.style.fontStyle = "normal";
            nomeElem.style.color = "#1e293b";
        }
        if (statusElem) {
            statusElem.className = "tag-ok";
            statusElem.innerText = "PUBLICADO";
        }
        if (cardElem) {
            cardElem.classList.remove('highlight-vacant');
        }
    }
};
    }
});

window.adicionarAoCarrinho = function(nome, preco) {
    const saldoAtual = 1250000; // Este valor deve vir do seu estado global ou HTML

    if (saldoAtual >= preco) {
        // Confirmação de compra
        const confirmar = confirm(`Deseja confirmar a aquisição de: ${nome} por R$ ${preco.toLocaleString('pt-BR')}?`);
        
        if (confirmar) {
            window.showGovNotification(
                "success", 
                "Pedido de Compra Enviado", 
                `A aquisição de ${nome} foi enviada para o Diário Oficial.`
            );
            
            // Aqui você dispararia a lógica para subtrair o saldo e adicionar à frota
            console.log(`Item comprado: ${nome}. Valor: ${preco}`);
        }
    } else {
        window.showGovNotification(
            "error", 
            "Saldo Insuficiente", 
            "A tesouraria não possui saldo para esta aquisição."
        );
    }
};

document.addEventListener('DOMContentLoaded', function() {
    const botoesFiltro = document.querySelectorAll('.btn-filter');
    const cards = document.querySelectorAll('.item-card');

    botoesFiltro.forEach(botao => {
        botao.addEventListener('click', function() {
            // Remove o estado ativo de todos e aplica ao clicado
            botoesFiltro.forEach(b => b.classList.remove('active'));
            this.classList.add('active');

            const categoriaSelecionada = this.getAttribute('data-category');

            cards.forEach(card => {
                const tipoCard = card.getAttribute('data-type');

                // Lógica: se for 'todos' ou se o tipo do card bater com o filtro
                if (categoriaSelecionada === 'todos' || categoriaSelecionada === tipoCard) {
                    card.style.display = 'block'; // Mostra
                } else {
                    card.style.display = 'none'; // Esconde
                }
            });
        });
    });
});

// --- LOGICA DE COMPRA (PORTAL DE AQUISIÇÕES) ---
window.adicionarAoCarrinho = function(nome, preco) {
    const precoFormatado = preco.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });

    // Envio para o servidor FiveM
    if (typeof GetParentResourceName !== 'undefined') {
        fetch(`https://${GetParentResourceName()}/comprarItem`, {
            method: 'POST',
            body: JSON.stringify({ item: nome, valor: preco })
        });
    }

    // Feedback visual usando sua função de notificação
    if (window.showGovNotification) {
        window.showGovNotification(
            "success", 
            "AQUISIÇÃO REGISTRADA", 
            `${nome} foi faturado por ${precoFormatado}.`
        );
    }
};

// --- LOGICA DE TROCA DE ABAS (CORRIGIDA) ---
window.mudarAba = function(idDaAba) {
    // 1. Esconde todas as abas
    const abas = document.querySelectorAll('.tab-view');
    abas.forEach(aba => {
        aba.style.display = 'none';
        aba.classList.remove('active');
    });

    // 2. Mostra a aba alvo
    const abaAlvo = document.getElementById('view-' + idDaAba);
    if (abaAlvo) {
        abaAlvo.style.display = 'flex'; // Usamos flex para manter o grid operacional
        abaAlvo.classList.add('active');
        
        // Atualiza títulos conforme a aba
        const pageTitle = document.getElementById('page-title');
        const breadPath = document.getElementById('bread-path');
        
        const titulos = {
            'aquisicoes': { t: 'Portal de Aquisições Governamentais', b: 'Patrimônio / Suprimentos' },
            'dashboard': { t: 'Painel de Controle Financeiro', b: 'Administração / Executivo' },
            'rh': { t: 'Gabinete de Gestão de Pessoas', b: 'Administração / RH' },
            'frota': { t: 'Gestão de Ativos e Frota SAMU', b: 'Patrimônio / Logística' }
        };

        if (titulos[idDaAba]) {
            pageTitle.innerText = titulos[idDaAba].t;
            breadPath.innerText = titulos[idDaAba].b;
        }
    }

    // 3. Atualiza o visual da Sidebar
    document.querySelectorAll('.nav-item').forEach(item => item.classList.remove('active'));
    if (event && event.currentTarget) {
        event.currentTarget.classList.add('active');
    }
};

// Variável global para simular o saldo (pode ser integrada ao seu sistema de backend)
let saldoTesouraria = 1250000;

window.adicionarAoCarrinho = function(nomeItem, preco) {
    if (saldoTesouraria >= preco) {
        // Confirmação
        const confirmacao = confirm(`Confirmar aquisição de ${nomeItem} por R$ ${preco.toLocaleString('pt-BR')}?`);
        
        if (confirmacao) {
            saldoTesouraria -= preco;
            
            // Atualiza o saldo visual na Dashboard
            const saldoElem = document.querySelector('.hero-card.balance h1');
            if (saldoElem) {
                saldoElem.innerText = `R$ ${saldoTesouraria.toLocaleString('pt-BR')}`;
            }

            // Notificação de Sucesso
            window.showGovNotification(
                "success", 
                "Compra Aprovada", 
                `${nomeItem} foi adicionado ao inventário e o saldo atualizado.`
            );

            // Log no Diário Oficial (Opcional)
            console.log(`[COMPRA] ${nomeItem} - R$ ${preco} | Saldo Restante: R$ ${saldoTesouraria}`);
        }
    } else {
        // Notificação de Erro
        window.showGovNotification(
            "error", 
            "Saldo Insuficiente", 
            "A SESAU não possui fundos suficientes para esta transação."
        );
    }
};

function requisitarReparo(prefixo) {
    // Simula a regra: A manutenção deve ser requisitada pelo batalhão
    const confirmacao = confirm(`O Batalhão confirma a requisição de manutenção para a unidade ${prefixo}?`);
    
    if (confirmacao) {
        window.showGovNotification(
            "success", 
            "Manutenção Solicitada", 
            `A unidade ${prefixo} foi enviada para a oficina central do Batalhão.`
        );
        
        // Log de simulação (Aqui você integraria com seu banco de dados)
        console.log(`[LOG] Manutenção requisitada pelo Batalhão para: ${prefixo}`);
    }
}

function solicitarManutencaoGeral() {
     window.showGovNotification(
        "error", 
        "Acesso Negado", 
        "Apenas o Comandante do Batalhão pode autorizar a manutenção total da frota."
    );
}

function enviarParaOficina(rowId, prefixo) {
    const confirmacao = confirm(`[BATALHÃO] Confirmar envio da unidade ${prefixo} para a oficina central? Ela ficará indisponível por 48 horas.`);
    
    if (confirmacao) {
        const tr = document.getElementById(rowId);
        
        // 1. Muda visualmente a linha para "Em Manutenção"
        tr.classList.add('vtr-in-repair');
        
        // 2. Atualiza o Status e o Botão
        const statusTd = tr.cells[4];
        const acaoTd = tr.cells[5];
        
        statusTd.innerHTML = `<span class="tag-info">NA OFICINA (48h 00m)</span>`;
        acaoTd.innerHTML = `<button class="btn-low" disabled>EM REPARO</button>`;

        // 3. Notificação oficial
        window.showGovNotification(
            "success", 
            "MISSÃO INICIADA", 
            `Viatura ${prefixo} entregue na oficina. Previsão de entrega: 2 dias.`
        );

        // 4. Lógica de Tempo (Simulação para o Front-end)
        // Em um sistema real, salvaríamos o timestamp no banco de dados.
        iniciarContagemRegressiva(rowId, 48 * 60 * 60); // 48 horas em segundos
    }
}

function iniciarContagemRegressiva(rowId, segundos) {
    const tr = document.getElementById(rowId);
    let tempoRestante = segundos;

    const intervalo = setInterval(() => {
        tempoRestante--;

        if (tempoRestante <= 0) {
            clearInterval(intervalo);
            finalizarReparo(rowId);
        } else {
            // Atualiza o texto do cronômetro na tabela
            const horas = Math.floor(tempoRestante / 3600);
            const minutos = Math.floor((tempoRestante % 3600) / 60);
            tr.cells[4].innerHTML = `<span class="tag-info">NA OFICINA (${horas}h ${minutos}m)</span>`;
        }
    }, 60000); // Atualiza a cada 1 minuto para não pesar o navegador
}

function finalizarReparo(rowId) {
    const tr = document.getElementById(rowId);
    tr.classList.remove('vtr-in-repair');
    
    // Restaura o estado operacional com 100% de saúde
    tr.cells[3].innerHTML = `<div class="health-bar"><div class="fill" style="width: 100%;"></div></div>`;
    tr.cells[4].innerHTML = `<span class="tag-ok">OPERACIONAL</span>`;
    tr.cells[5].innerHTML = `<button class="btn-low" onclick="requisitarReparo()">REVISAR</button>`;

    window.showGovNotification(
        "success", 
        "REPARO CONCLUÍDO", 
        "A viatura foi liberada pela oficina do Batalhão e está pronta para uso."
    );
}

// PASSO 1: Batalhão autoriza a manutenção
function solicitarManutencao(idCurto, prefixo) {
    const statusTd = document.getElementById(`status-${idCurto}`);
    const acaoTd = document.getElementById(`acao-${idCurto}`);

    statusTd.className = "tag-waiting";
    statusTd.innerText = "AGUARDANDO ENTREGA";
    
    // Altera o botão para "Confirmar Entrega" (o jogador deve clicar aqui quando chegar na oficina no mapa)
    acaoTd.innerHTML = `<button class="btn-checkin" onclick="confirmarEntregaNaOficina('${idCurto}', '${prefixo}')">ENTREGAR NA OFICINA</button>`;

    window.showGovNotification(
        "info", 
        "REPARO AUTORIZADO", 
        `Leve a unidade ${prefixo} até a oficina do Batalhão para iniciar o conserto.`
    );
}

// PASSO 2: O cronômetro só começa AQUI
function confirmarEntregaNaOficina(idCurto, prefixo) {
    const row = document.getElementById(`vtr-${idCurto}`);
    const statusTd = document.getElementById(`status-${idCurto}`);
    const acaoTd = document.getElementById(`acao-${idCurto}`);

    // Bloqueia a linha (veículo está fisicamente na oficina agora)
    row.classList.add('vtr-in-repair');
    
    statusTd.className = "tag-info";
    statusTd.innerHTML = "NA OFICINA (48h 00m)";
    acaoTd.innerHTML = `<button class="btn-low" disabled>EM REPARO</button>`;

    window.showGovNotification(
        "success", 
        "MISSÃO INICIADA", 
        `Viatura ${prefixo} entregue. O reparo de 2 dias começou agora.`
    );

    // Inicia a contagem real de 48 horas (calculado em segundos)
    iniciarCronometroReparo(idCurto, 48 * 3600);
}

function iniciarCronometroReparo(idCurto, segundos) {
    let tempo = segundos;
    const statusTd = document.getElementById(`status-${idCurto}`);

    const timer = setInterval(() => {
        tempo -= 60; // Reduz 1 minuto por ciclo
        
        if (tempo <= 0) {
            clearInterval(timer);
            finalizarManutencao(idCurto);
        } else {
            const h = Math.floor(tempo / 3600);
            const m = Math.floor((tempo % 3600) / 60);
            statusTd.innerText = `NA OFICINA (${h}h ${m}m)`;
        }
    }, 60000); // 1 minuto
}

function finalizarManutencao(idCurto) {
    const row = document.getElementById(`vtr-${idCurto}`);
    const statusTd = document.getElementById(`status-${idCurto}`);
    const acaoTd = document.getElementById(`acao-${idCurto}`);

    row.classList.remove('vtr-in-repair');
    statusTd.className = "tag-ok";
    statusTd.innerText = "OPERACIONAL";
    
    // Reseta a vida para 100%
    row.cells[3].innerHTML = `<div class="health-bar"><div class="fill" style="width: 100%;"></div></div>`;
    
    // Reseta o botão original
    acaoTd.innerHTML = `<button class="btn-confirm-rh" style="padding: 8px; font-size: 10px;" onclick="solicitarManutencao('${idCurto}', '${row.cells[0].innerText}')">SOLICITAR REPARO</button>`;
}

function requisitarManutencaoEquip(nomeEquip) {
    const confirmacao = confirm(`Deseja abrir uma requisição de manutenção para o equipamento: ${nomeEquip}?`);
    
    if (confirmacao) {
        window.showGovNotification(
            "info", 
            "REQUISIÇÃO ENVIADA", 
            `A equipe técnica do Batalhão foi notificada sobre o ${nomeEquip}.`
        );
        // Aqui você pode adicionar a lógica de mudar o status do card para "Em Manutenção"
    }
}

function filtrarEquip(btn, categoria) {
    // Remove active de todos os botões do filtro de equipamentos
    const botoes = btn.parentElement.querySelectorAll('.btn-filter');
    botoes.forEach(b => b.classList.remove('active'));
    btn.classList.add('active');

    const cards = document.querySelectorAll('.equip-status-card');
    cards.forEach(card => {
        if (categoria === 'todos' || card.getAttribute('data-subcat') === categoria) {
            card.style.display = 'flex';
        } else {
            card.style.display = 'none';
        }
    });
}