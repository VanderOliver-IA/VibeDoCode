#!/usr/bin/env bash
# =============================================================================
# VibeDoCode — accounts.sh
# Gestão de múltiplas contas Gmail para o Antigravity (Gemini CLI)
#
# Funciona com auth via browser OAuth (não requer gcloud CLI)
# Opera diretamente nos arquivos de credenciais do Antigravity:
#   ~/.gemini/oauth_creds.json      ← Token OAuth ativo
#   ~/.gemini/google_accounts.json  ← Email da conta ativa
# =============================================================================

set -euo pipefail

# --- Configuração ---
GEMINI_DIR="$HOME/.gemini"
VAULT_DIR="$HOME/.vibedocode/vault"
ACCOUNTS_FILE="$VAULT_DIR/accounts.json"
MAX_ACCOUNTS=5

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Helpers ---
banner() {
    echo ""
    echo -e "${CYAN}${BOLD}🔐 VibeDoCode — Gestão de Contas${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

ensure_vault() {
    mkdir -p "$VAULT_DIR"
    if [[ ! -f "$ACCOUNTS_FILE" ]]; then
        echo '{"accounts": [], "max_accounts": 5}' > "$ACCOUNTS_FILE"
    fi
}

get_active_email() {
    if [[ -f "$GEMINI_DIR/google_accounts.json" ]]; then
        python3 -c "
import json, sys
with open('$GEMINI_DIR/google_accounts.json') as f:
    d = json.load(f)
print(d.get('active', 'desconhecido'))
" 2>/dev/null || echo "desconhecido"
    else
        echo "nao configurado"
    fi
}

get_accounts() {
    python3 -c "
import json
with open('$ACCOUNTS_FILE') as f:
    d = json.load(f)
print(json.dumps(d.get('accounts', [])))
" 2>/dev/null || echo "[]"
}

account_count() {
    python3 -c "
import json
with open('$ACCOUNTS_FILE') as f:
    d = json.load(f)
print(len(d.get('accounts', [])))
" 2>/dev/null || echo "0"
}

# --- Comando: list ---
cmd_list() {
    banner
    ensure_vault

    local active_email
    active_email=$(get_active_email)

    local accounts
    accounts=$(get_accounts)

    local count
    count=$(echo "$accounts" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")

    echo ""
    if [[ "$count" -eq 0 ]]; then
        echo -e "  ${YELLOW}Nenhuma conta salva no vault ainda.${RESET}"
        echo -e "  Use ${BOLD}/vibe-accounts save <nome>${RESET} para salvar a conta atual."
        echo -e "  Use ${BOLD}/vibe-accounts add <email> <nome>${RESET} após fazer login no browser."
    else
        python3 -c "
import json
accounts = json.loads('$accounts'.replace(\"'\", '\"') if False else open('$ACCOUNTS_FILE').read())['accounts']
active = '$active_email'
max_slots = 5

for i, acc in enumerate(accounts, 1):
    name = acc.get('name','?')
    email = acc.get('email','?')
    is_active = email == active
    status = '✅ [ATIVA] ' if is_active else '   [PRONTA]'
    print(f'  {i}. {status} {email:<35} ({name})')

for i in range(len(accounts)+1, max_slots+1):
    print(f'  {i}.    [VAZIA]  —')

print()
print(f'  Conta ativa agora: {active}')
"
    fi

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${BOLD}Uso:${RESET} vibe-accounts switch <nome> | save <nome> | add <email> <nome>"
    echo ""
}

# --- Comando: status ---
cmd_status() {
    local active_email
    active_email=$(get_active_email)
    echo ""
    echo -e "${GREEN}✅ Conta ativa no Antigravity: ${BOLD}$active_email${RESET}"
    echo ""
}

# --- Comando: save (salva conta atual no vault) ---
cmd_save() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Erro: Informe um nome para a conta.${RESET}"
        echo -e "   Uso: vibe-accounts save <nome>"
        exit 1
    fi

    ensure_vault

    local active_email
    active_email=$(get_active_email)

    if [[ "$active_email" == "desconhecido" || "$active_email" == "nao configurado" ]]; then
        echo -e "${RED}❌ Nenhuma conta ativa encontrada no Antigravity.${RESET}"
        echo -e "   Faça login primeiro e depois execute este comando."
        exit 1
    fi

    # Verifica limite
    local count
    count=$(account_count)
    if [[ "$count" -ge "$MAX_ACCOUNTS" ]]; then
        echo -e "${RED}❌ Limite de $MAX_ACCOUNTS contas atingido.${RESET}"
        echo -e "   Remova uma conta antes de adicionar outra."
        exit 1
    fi

    # Cria diretório do vault para esta conta
    local account_dir="$VAULT_DIR/$name"
    mkdir -p "$account_dir"

    # Copia credenciais atuais
    cp "$GEMINI_DIR/oauth_creds.json" "$account_dir/oauth_creds.json"
    cp "$GEMINI_DIR/google_accounts.json" "$account_dir/google_accounts.json"

    # Registra conta no accounts.json
    python3 -c "
import json, datetime
with open('$ACCOUNTS_FILE') as f:
    data = json.load(f)

accounts = data.get('accounts', [])

# Remove se já existe com mesmo nome
accounts = [a for a in accounts if a.get('name') != '$name']

accounts.append({
    'name': '$name',
    'email': '$active_email',
    'vault_path': '$account_dir',
    'saved_at': datetime.datetime.now().isoformat()
})

data['accounts'] = accounts

with open('$ACCOUNTS_FILE', 'w') as f:
    json.dump(data, f, indent=2)

print('saved')
"

    echo ""
    echo -e "${GREEN}✅ Conta ${BOLD}$active_email${RESET}${GREEN} salva no vault como ${BOLD}\"$name\"${RESET}"
    echo -e "   Para trocar: ${BOLD}vibe-accounts switch $name${RESET}"
    echo ""
}

# --- Comando: switch ---
cmd_switch() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Erro: Informe o nome da conta.${RESET}"
        echo -e "   Uso: vibe-accounts switch <nome>"
        echo -e "   Contas disponíveis:"
        cmd_list
        exit 1
    fi

    ensure_vault

    local account_dir="$VAULT_DIR/$name"
    if [[ ! -d "$account_dir" ]]; then
        echo -e "${RED}❌ Conta \"$name\" não encontrada no vault.${RESET}"
        echo -e "   Use ${BOLD}vibe-accounts list${RESET} para ver contas disponíveis."
        exit 1
    fi

    if [[ ! -f "$account_dir/oauth_creds.json" ]]; then
        echo -e "${RED}❌ Credenciais da conta \"$name\" estão corrompidas ou incompletas.${RESET}"
        exit 1
    fi

    # Backup da conta atual antes de trocar
    local current_email
    current_email=$(get_active_email)
    echo -e "${YELLOW}⚠️  Trocando de conta...${RESET}"
    echo -e "   De: ${BOLD}$current_email${RESET}"

    # Aplica credenciais da conta alvo
    cp "$account_dir/oauth_creds.json" "$GEMINI_DIR/oauth_creds.json"
    cp "$account_dir/google_accounts.json" "$GEMINI_DIR/google_accounts.json"

    local new_email
    new_email=$(get_active_email)
    echo -e "   Para: ${BOLD}${GREEN}$new_email${RESET}"
    echo ""
    echo -e "${GREEN}✅ Conta trocada com sucesso!${RESET}"
    echo -e "${YELLOW}🔄 IMPORTANTE: Reinicie o Antigravity para usar a nova conta.${RESET}"
    echo ""
}

# --- Comando: remove ---
cmd_remove() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Erro: Informe o nome da conta.${RESET}"
        echo -e "   Uso: vibe-accounts remove <nome>"
        exit 1
    fi

    ensure_vault

    local account_dir="$VAULT_DIR/$name"
    if [[ ! -d "$account_dir" ]]; then
        echo -e "${RED}❌ Conta \"$name\" não encontrada.${RESET}"
        exit 1
    fi

    # Verifica se não é a conta ativa
    local active_email
    active_email=$(get_active_email)
    local account_email
    account_email=$(python3 -c "
import json
with open('$ACCOUNTS_FILE') as f:
    data = json.load(f)
for a in data.get('accounts',[]):
    if a.get('name') == '$name':
        print(a.get('email',''))
        break
" 2>/dev/null || echo "")

    if [[ "$account_email" == "$active_email" ]]; then
        echo -e "${RED}❌ Não é possível remover a conta ativa.${RESET}"
        echo -e "   Troque para outra conta antes de remover esta."
        exit 1
    fi

    # Remove diretório do vault
    rm -rf "$account_dir"

    # Atualiza accounts.json
    python3 -c "
import json
with open('$ACCOUNTS_FILE') as f:
    data = json.load(f)
data['accounts'] = [a for a in data.get('accounts',[]) if a.get('name') != '$name']
with open('$ACCOUNTS_FILE','w') as f:
    json.dump(data, f, indent=2)
"

    echo -e "${GREEN}✅ Conta \"$name\" removida do vault.${RESET}"
    echo ""
}

# --- Dispatcher ---
main() {
    local cmd="${1:-list}"
    shift || true

    case "$cmd" in
        list)       cmd_list ;;
        status)     cmd_status ;;
        save)       cmd_save "$@" ;;
        switch)     cmd_switch "$@" ;;
        remove)     cmd_remove "$@" ;;
        help|--help|-h)
            echo ""
            echo -e "${BOLD}VibeDoCode — accounts${RESET}"
            echo "  list            Lista todas as contas no vault"
            echo "  status          Mostra a conta ativa agora"
            echo "  save <nome>     Salva conta atual no vault"
            echo "  switch <nome>   Troca para outra conta do vault"
            echo "  remove <nome>   Remove conta do vault"
            echo ""
            ;;
        *)
            echo -e "${RED}❌ Subcomando desconhecido: $cmd${RESET}"
            echo -e "   Use: vibe-accounts help"
            exit 1
            ;;
    esac
}

main "$@"
