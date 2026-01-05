/**
 * Sistema de Governo - Lógica Principal
 * Data: 03/01/2026
 */

// 1. Navegação entre Abas
function showTab(tabId, element) {
    // Esconde todas as seções
    const tabs = document.querySelectorAll('.tab-content');
    tabs.forEach(tab => tab.classList.remove('active'));

    // Remove o estado ativo de todos os itens do menu
    const navItems = document.querySelectorAll('.nav-item');
    navItems.forEach(item => item.classList.remove('active'));

    // Ativa a aba e o item de menu selecionados
    document.getElementById(tabId).classList.add('active');
    element.classList.add('active');
}

// 2. Controle do Modal de Nomeação
function toggleModal(show) {
    const modal = document.getElementById('modalNomear');
    if (modal) {
        modal.style.display = show ? 'flex' : 'none';
    }
}

// 3. Sistema de Notificações (Toasts)
function showNotification(message, type = 'success') {
    const container = document.getElementById('toast-container');
    
    // Criar o elemento da notificação
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    
    // Definir o ícone com base no tipo
    const icon = type === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle';
    
    toast.innerHTML = `
        <i class="fas ${icon}"></i>
        <div class="toast-content">
            <span class="toast-msg">${message}</span>
        </div>
    `;

    // Adicionar ao container
    container.appendChild(toast);

    // Trigger da animação de entrada (CSS transition)
    setTimeout(() => {
        toast.classList.add('show');
    }, 100);

    // Remover automaticamente após 3.5 segundos
    setTimeout(() => {
        toast.classList.remove('show');
        // Espera a animação de saída terminar para remover do DOM
        setTimeout(() => {
            toast.remove();
        }, 400);
    }, 3500);
}

// 4. Lógica de Confirmação de Nomeação
function confirmarNomeacao() {
    // Pegar os valores dos inputs (certifique-se que os IDs batem com seu HTML)
    const cidInput = document.getElementById('cid');
    const nomeInput = document.getElementById('nome');
    const cargoInput = document.getElementById('cargo');

    const cid = cidInput ? cidInput.value.trim() : "";
    const nome = nomeInput ? nomeInput.value.trim() : "";

    // Validação
    if (cid !== "" && nome !== "") {
        // Sucesso
        showNotification(`Sucesso! ${nome} foi nomeado(a) com sucesso.`, 'success');
        
        // Aqui você pode adicionar a lógica para inserir na lista de membros via API ou DOM
        
        // Fechar modal e limpar campos
        toggleModal(false);
        cidInput.value = "";
        nomeInput.value = "";
    } else {
        // Erro
        showNotification("Erro ao nomear: Preencha todos os campos obrigatórios.", "error");
    }
}

// 5. Fechar modal ao clicar fora do card (clique no overlay)
window.addEventListener('click', function(event) {
    const modal = document.getElementById('modalNomear');
    if (event.target === modal) {
        toggleModal(false);
    }
});

// Abre o modal de análise com os dados dinâmicos
function abrirAnaliseEmenda(titulo, valor, autor, descricao) {
    document.getElementById('analiseTitulo').innerText = titulo;
    document.getElementById('analiseValor').innerText = valor;
    document.getElementById('analiseAutor').innerText = autor;
    document.getElementById('analiseDescricao').innerText = descricao;
    
    document.getElementById('modalAnalise').style.display = 'flex';
}

// Fecha o modal de análise
function fecharAnalise() {
    document.getElementById('modalAnalise').style.display = 'none';
}

// Processa a decisão do Governador
function decisaoEmenda(status) {
    const projeto = document.getElementById('analiseTitulo').innerText;
    
    if (status === 'Aprovada') {
        showNotification(`Emenda "${projeto}" aprovada com sucesso!`, 'success');
    } else {
        showNotification(`Emenda "${projeto}" foi indeferida.`, 'error');
    }
    
    fecharAnalise();
}

// Fechar modal ao clicar fora (ajuste para incluir o novo modal)
window.addEventListener('click', function(event) {
    const modalNomear = document.getElementById('modalNomear');
    const modalAnalise = document.getElementById('modalAnalise');
    
    if (event.target === modalNomear) toggleModal(false);
    if (event.target === modalAnalise) fecharAnalise();
});

// Abre o modal de demanda com os detalhes
function abrirAnaliseDemanda(titulo, autor, descricao) {
    document.getElementById('demandaTitulo').innerText = titulo;
    document.getElementById('demandaAutor').innerText = autor;
    document.getElementById('demandaDescricao').innerText = descricao;
    document.getElementById('respostaGoverno').value = ""; // Limpa resposta anterior
    
    document.getElementById('modalDemanda').style.display = 'flex';
}

// Fecha o modal de demanda
function fecharDemanda() {
    document.getElementById('modalDemanda').style.display = 'none';
}

// Envia a resposta e mostra notificação
function enviarRespostaDemanda() {
    const resposta = document.getElementById('respostaGoverno').value;
    const titulo = document.getElementById('demandaTitulo').innerText;

    if (resposta.trim() !== "") {
        showNotification(`Resposta enviada para: ${titulo}`, 'success');
        fecharDemanda();
        // Aqui você pode adicionar a lógica para remover a demanda da lista ou marcar como lida
    } else {
        showNotification("Por favor, escreva uma providência antes de concluir.", "error");
    }
}

// Atualização do listener de clique fora do modal
window.addEventListener('click', function(event) {
    const modals = {
        'modalNomear': toggleModal,
        'modalAnalise': fecharAnalise,
        'modalDemanda': fecharDemanda
    };
    
    for (let id in modals) {
        if (event.target === document.getElementById(id)) {
            modals[id](false);
        }
    }
});

let leiAtiva = null;
let idCardParaRemover = null;

function abrirAnaliseLei(protocolo, titulo, texto, idElemento) {
    leiAtiva = { protocolo, titulo, texto };
    idCardParaRemover = idElemento;
    
    document.getElementById('leiTitulo').innerText = titulo;
    document.getElementById('leiProtocolo').innerText = protocolo;
    document.getElementById('leiTexto').innerText = texto;
    document.getElementById('leiJustificativa').value = ""; // Limpa campo anterior
    
    document.getElementById('modalLei').style.display = 'flex';
}

function decisaoLei(status) {
    const justificativa = document.getElementById('leiJustificativa').value;

    // Validação de motivo para ações negativas
    if ((status === 'Vetado' || status === 'Correcao') && justificativa.trim().length < 5) {
        showNotification("É necessário descrever o motivo da decisão.", "error");
        return;
    }

    // Remover da lista de pendências
    if (idCardParaRemover) {
        const card = document.getElementById(idCardParaRemover);
        if (card) card.remove();
    }

    // Processar conforme a decisão do Governador
    if (status === 'Sancionado') {
        const listaPenal = document.getElementById('codigo-penal-lista');
        const novoArt = document.createElement('div');
        novoArt.className = 'mini-box';
        novoArt.style.cssText = 'background: #e8f5e9; border-left: 3px solid #34c759; font-weight: 600;';
        novoArt.innerHTML = `<strong>${leiAtiva.protocolo}</strong> - ${leiAtiva.titulo} <br><small>Promulgada em 04/01/2026</small>`;
        listaPenal.prepend(novoArt);
        showNotification("Lei sancionada e publicada!", "success");

    } else if (status === 'Vetado') {
        const listaVetos = document.getElementById('historico-vetos-lista');
        moverParaHistorico(listaVetos, "#ff3b30", justificativa);
        showNotification("Projeto de lei vetado.", "error");

    } else if (status === 'Correcao') {
        const listaCorrecao = document.getElementById('historico-correcao-lista');
        moverParaHistorico(listaCorrecao, "#ff9500", justificativa);
        showNotification("Enviado para ajustes na Câmara.", "warning");
    }

    document.getElementById('modalLei').style.display = 'none';
}

function moverParaHistorico(container, cor, motivo) {
    // Remove a mensagem de "vazio" se existir
    if (container.querySelector('p')) container.innerHTML = "";
    
    const div = document.createElement('div');
    div.className = 'mini-box';
    div.style.borderLeft = `4px solid ${cor}`;
    div.innerHTML = `
        <div style="font-size: 13px;">
            <span style="font-weight: 800; color: ${cor};">${leiAtiva.protocolo}</span><br>
            <strong>${leiAtiva.titulo}</strong><br>
            <div style="margin-top: 5px; padding: 8px; background: #fff; border-radius: 6px; font-size: 11px;">
                <b>Motivo:</b> ${motivo}
            </div>
        </div>
    `;
    container.prepend(div);
}

let emendaAtiva = null;
let idEmendaRemover = null;

function abrirAnaliseEmenda(titulo, valor, autor, descricao, idElemento) {
    emendaAtiva = { titulo, valor, autor, descricao };
    idEmendaRemover = idElemento;

    document.getElementById('emendaTitulo').innerText = titulo;
    document.getElementById('emendaAutor').innerText = autor;
    document.getElementById('emendaValor').innerText = valor;
    document.getElementById('emendaDescricao').innerText = descricao;
    document.getElementById('emendaJustificativa').value = ""; // Limpa o campo
    
    document.getElementById('modalEmenda').style.display = 'flex';
}

function decisaoEmenda(status) {
    const justificativa = document.getElementById('emendaJustificativa').value;

    // Validação: Justificativa obrigatória APENAS para Reprovar
    if (status === 'Reprovada' && justificativa.trim().length < 5) {
        showNotification("Insira um motivo para a reprovação da emenda.", "error");
        return;
    }

    // Remove da lista superior
    if (idEmendaRemover) {
        const el = document.getElementById(idEmendaRemover);
        if (el) el.remove();
    }

    if (status === 'Aprovada') {
        const lista = document.getElementById('historico-emendas-aprovadas');
        if (lista.querySelector('p')) lista.innerHTML = "";
        
        const div = document.createElement('div');
        div.className = 'mini-box';
        div.style.borderLeft = '4px solid #34c759';
        div.innerHTML = `
            <strong>${emendaAtiva.titulo}</strong><br>
            <small>Valor: ${emendaAtiva.valor} | Autor: ${emendaAtiva.autor}</small>
        `;
        lista.prepend(div);
        showNotification("Emenda aprovada com sucesso!", "success");

    } else {
        const lista = document.getElementById('historico-emendas-reprovadas');
        if (lista.querySelector('p')) lista.innerHTML = "";

        const div = document.createElement('div');
        div.className = 'mini-box';
        div.style.borderLeft = '4px solid #ff3b30';
        div.innerHTML = `
            <strong>${emendaAtiva.titulo}</strong><br>
            <small style="color: #ff3b30;"><b>Motivo do Veto:</b> ${justificativa}</small>
        `;
        lista.prepend(div);
        showNotification("Emenda reprovada e motivo registrado.", "error");
    }

    document.getElementById('modalEmenda').style.display = 'none';
}