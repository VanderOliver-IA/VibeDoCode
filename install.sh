#!/usr/bin/env bash
# =============================================================================
# VibeDoCode — install.sh
# Instalador da extensão VibeDoCode para o Antigravity (Gemini CLI)
# =============================================================================
# Uso: curl -fsSL https://raw.githubusercontent.com/VanderOliver-IA/VibeDoCode/main/install.sh | bash
# =============================================================================

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

REPO="VanderOliver-IA/VibeDoCode"
INSTALL_DIR="$HOME/.vibedocode"
VAULT_DIR="$INSTALL_DIR/vault"

echo ""
echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║    VibeDoCode — Facilitando o Antigravity     ║${RESET}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════╝${RESET}"
echo ""

# --- Verifica pré-requisitos ---
echo -e "  ${BOLD}Verificando pré-requisitos...${RESET}"

if ! command -v gemini &>/dev/null; then
    echo -e "  ${RED}❌ Antigravity (gemini) não encontrado.${RESET}"
    echo -e "     Instale o Gemini CLI primeiro: https://geminicli.com"
    exit 1
fi
echo -e "  ${GREEN}✅ Antigravity (gemini) encontrado${RESET}"

if ! command -v node &>/dev/null; then
    echo -e "  ${YELLOW}⚠️  Node.js não encontrado — MCP Server não funcionará.${RESET}"
    echo -e "     Instale: https://nodejs.org"
else
    echo -e "  ${GREEN}✅ Node.js $(node --version) encontrado${RESET}"
fi

if ! command -v python3 &>/dev/null; then
    echo -e "  ${YELLOW}⚠️  Python3 não encontrado — Monitor de cotas não funcionará.${RESET}"
else
    echo -e "  ${GREEN}✅ Python3 $(python3 --version 2>&1 | cut -d' ' -f2) encontrado${RESET}"
fi

if ! command -v rsync &>/dev/null; then
    echo -e "  ${YELLOW}⚠️  rsync não encontrado — Sync de pastas não funcionará.${RESET}"
    echo -e "     Instale: sudo apt install rsync${RESET}"
else
    echo -e "  ${GREEN}✅ rsync encontrado${RESET}"
fi

echo ""

# --- Cria diretório de dados ---
echo -e "  ${BOLD}Criando estrutura de dados...${RESET}"
mkdir -p "$VAULT_DIR"
mkdir -p "$INSTALL_DIR"

if [[ ! -f "$VAULT_DIR/accounts.json" ]]; then
    echo '{"accounts": [], "max_accounts": 5}' > "$VAULT_DIR/accounts.json"
fi

echo -e "  ${GREEN}✅ Vault criado: $VAULT_DIR${RESET}"

# --- Instala a extensão via gemini CLI ---
echo ""
echo -e "  ${BOLD}Instalando extensão no Antigravity...${RESET}"

if gemini extensions install "github.com/$REPO" 2>/dev/null; then
    echo -e "  ${GREEN}✅ Extensão instalada via gemini CLI${RESET}"
else
    echo -e "  ${YELLOW}⚠️  Instalação via 'gemini extensions install' falhou.${RESET}"
    echo -e "     Tente manualmente: ${BOLD}gemini extensions install github.com/$REPO${RESET}"
fi

# --- Instala dependências Node.js do MCP Server ---
echo ""
echo -e "  ${BOLD}Instalando dependências do MCP Server...${RESET}"
EXT_DIR="$HOME/.gemini/extensions/vibedocode"
if [[ -d "$EXT_DIR/mcp-server" ]]; then
    (cd "$EXT_DIR/mcp-server" && npm install --silent) && \
        echo -e "  ${GREEN}✅ Dependências Node.js instaladas${RESET}" || \
        echo -e "  ${YELLOW}⚠️  Falha ao instalar dependências Node.js${RESET}"
fi

# --- Finalização ---
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}${BOLD}✅ VibeDoCode instalado com sucesso!${RESET}"
echo ""
echo -e "  ${BOLD}Próximos passos:${RESET}"
echo -e "  1. Reinicie o Antigravity"
echo -e "  2. ${BOLD}/vibe-accounts save pessoal${RESET} — salva sua conta atual"
echo -e "  3. ${BOLD}/vibe-accounts list${RESET} — veja suas contas"
echo -e "  4. ${BOLD}/vibe-quota${RESET} — monitore seu uso"
echo ""
echo -e "  ${CYAN}📖 Docs: https://github.com/$REPO${RESET}"
echo ""
