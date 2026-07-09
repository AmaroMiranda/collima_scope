# CollimaScope

**Assistente visual de colimação por câmera do celular** — App Flutter/Dart open source para auxiliar a colimação de telescópios Newtonianos e Dobsonianos usando apenas o seu smartphone.

## O que é colimação?

Colimação é o alinhamento dos espelhos de um telescópio para ótimo desempenho óptico. Um telescópio desalinhado produz imagens distorcidas e perde qualidade visual.

O **CollimaScope** torna esse processo mais fácil usando:

- 📱 A câmera do seu celular como sensor
- 🎯 Círculos de referência perfeitos (nunca achatados)
- 📐 Sobreposição visual com múltiplas guias
- 📖 Guia passo a passo intuitivo
- 💾 Histórico de sessões com antes/depois
- 🌙 Modo vermelho para preservar a adaptação noturna

## Características principais

### ✅ Implementadas (MVP)

- **Suporte a Newtonianos e Dobsonianos** com perfis customizáveis
- **Viewport sem distorção** — proporção 1:1 mantida em qualquer orientação
- **Editor visual intuitivo** com seleção de qualquer guia da sessão
- **Guia educativo correto** em 7 etapas com aviso sobre offset do secundário
- **Histórico persistente** com capturas antes/depois e exportação
- **Modo vermelho** para preservar adaptação ao escuro
- **Modo avançado** para usuários experientes pularem calibração

### 🚀 Planejado (V2+)

- Detecção automática de círculos com OpenCV
- Análise de desalinhamento assistida
- Suporte a SCT, RC e refratores

## Como usar

### 1. Instalar

Baixe o APK mais recente em [Releases](../../releases).

**Requisitos:** Android 16+, câmera traseira, ~60 MB

### 2. Começar

1. Conceda permissão de câmera
2. Cadastre seu telescópio
3. Escolha modo automático ou avançado
4. Siga as 7 etapas do guia

### 3. Editor de guias

Toque em qualquer círculo para abrir o painel de edição:
- Ajuste raio, espessura, opacidade
- Escolha entre 6 cores presets
- Bloqueie ou oculte guias conforme necessário

## Arquitetura

```
lib/
  app/              # App principal, tema, rotas
  core/             # Geometria, câmera, viewport, storage
  features/
    collimation/    # Lógica + tela principal
    telescope_profile/
    adapter_profile/
    history/
    guide/
  shared/           # Widgets, painters
```

## Stack técnico

- Flutter 3.44.4 • Dart 3.12.2 • Material Design 3
- Riverpod 2.6.1 (estado) • GoRouter 14.8.1 (navegação)
- camera 0.11.0 • shared_preferences • intl

## Desenvolvimento

```bash
git clone https://github.com/amaro-miranda/collima_scope.git
cd collima_scope
flutter pub get
flutter run

# Testes
flutter test

# Build release
flutter build apk --release
```

## Segurança

- ✅ Nenhuma chave de API armazenada
- ✅ Sem rastreamento de dados
- ✅ Totalmente offline
- ✅ Permissões mínimas (apenas câmera)
- ✅ Dados salvos localmente

## Licença

[MIT License](LICENSE) — Use, modifique e distribua livremente.

## Contribuindo

1. Fork o repositório
2. Crie uma branch (`git checkout -b feature/sua-ideia`)
3. Commit com mensagens descritivas
4. Push e abra um PR

**Diretrizes:** Respeite a regra crítica — **círculos nunca achatam**. Teste em dispositivo real. Atualize a spec se mudar comportamento óptico.

## FAQ

**P: Preciso de um adaptador?**  
R: Não é obrigatório, mas com um adaptador centralizado no focador, a precisão melhora muito.

**P: Funciona em iPhone?**  
R: Atualmente apenas Android. iOS pode ser adicionado em V2.

**P: Como exporto as imagens?**  
R: No histórico, toque em uma sessão → "Exportar imagem com overlay".

## Créditos

Desenvolvido por **Amaro Miranda** 🔭✨

CollimaScope — Seu assistente visual de colimação, sempre no seu bolso. 📱
