#!/usr/bin/env bash
# =============================================================================
# VibeDoCode — sync.sh
# Sincronismo de pastas compartilhadas do workspace Antigravity
# =============================================================================

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
GRAY='\033[0;90m'
RESET='\033[0m'

CONFIG_FILE="$HOME/.vibedocode/sync-paths.json"
LOG_FILE="$HOME/.vibedocode/sync.log"

# --- Detecta pastas do workspace automaticamente ---
detect_workspace_paths() {
    local base_project="/home/vanderoliver/Antigravity/Projetos/01 - Em Andamento/13-Extensao Antigravity"
    local paths=()

    for folder in "Shared-Assets" "Shared-Docs-APIs" "Shared-IPC"; do
        if [[ -d "$base_project/$folder" ]]; then
            paths+=("$base_project/$folder")
        fi
    done

    printf '%s\n' "${paths[@]}"
}

ensure_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    mkdir -p "$(dirname "$LOG_FILE")"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        # Cria config com pastas detectadas automaticamente
        local detected
        detected=$(detect_workspace_paths | python3 -c "
import sys, json
paths = [line.strip() for line in sys.stdin if line.strip()]
print(json.dumps({'paths': paths, 'destination': '/home/vanderoliver/Antigravity/Sync'}, indent=2))
")
        echo "$detected" > "$CONFIG_FILE"
        echo -e "${YELLOW}⚙️  Config criada automaticamente: $CONFIG_FILE${RESET}"
    fi
}

get_paths() {
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    d = json.load(f)
for p in d.get('paths', []):
    print(p)
" 2>/dev/null || true
}

get_destination() {
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    d = json.load(f)
print(d.get('destination', '$HOME/Antigravity/Sync'))
" 2>/dev/null || echo "$HOME/Antigravity/Sync"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

banner() {
    echo ""
    echo -e "${CYAN}${BOLD}🔄 VibeDoCode — Sincronismo de Pastas${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# --- Comando: run ---
cmd_run() {
    local dry_run="${1:-false}"
    banner
    ensure_config

    local paths
    mapfile -t paths < <(get_paths)

    if [[ ${#paths[@]} -eq 0 ]]; then
        echo -e "  ${YELLOW}Nenhuma pasta configurada para sync.${RESET}"
        echo -e "  Edite: ${BOLD}$CONFIG_FILE${RESET}"
        exit 0
    fi

    local dest
    dest=$(get_destination)
    mkdir -p "$dest"

    echo ""
    echo -e "  ${BOLD}Destino:${RESET} $dest"
    echo -e "  ${BOLD}Pastas:${RESET} ${#paths[@]} configuradas"
    echo ""

    local errors=0
    for src_path in "${paths[@]}"; do
        local folder_name
        folder_name=$(basename "$src_path")

        if [[ ! -d "$src_path" ]]; then
            echo -e "  ${RED}❌ Não encontrada: $src_path${RESET}"
            ((errors++)) || true
            continue
        fi

        if [[ "$dry_run" == "true" ]]; then
            echo -e "  ${GRAY}[DRY-RUN]${RESET} ${BOLD}$folder_name${RESET}"
            rsync -avzn --delete "$src_path/" "$dest/$folder_name/" 2>/dev/null | grep -E "^(>f|>d|deleting)" | head -20 || true
        else
            echo -ne "  📁 ${BOLD}$folder_name${RESET} ... "
            local result
            result=$(rsync -az --delete "$src_path/" "$dest/$folder_name/" 2>&1) || true
            echo -e "${GREEN}✅${RESET}"
            log "SYNC $src_path → $dest/$folder_name"
        fi
    done

    echo ""
    if [[ "$dry_run" == "true" ]]; then
        echo -e "  ${YELLOW}[DRY-RUN] Nenhum arquivo foi modificado.${RESET}"
    elif [[ "$errors" -eq 0 ]]; then
        echo -e "  ${GREEN}✅ Sincronismo concluído com sucesso!${RESET}"
        log "SYNC_COMPLETE success"
    else
        echo -e "  ${YELLOW}⚠️  Concluído com $errors erro(s).${RESET}"
        log "SYNC_COMPLETE errors=$errors"
    fi
    echo ""
}

# --- Comando: status ---
cmd_status() {
    banner
    ensure_config

    local paths
    mapfile -t paths < <(get_paths)
    local dest
    dest=$(get_destination)

    echo ""
    for src_path in "${paths[@]}"; do
        local folder_name
        folder_name=$(basename "$src_path")
        local dest_path="$dest/$folder_name"

        if [[ ! -d "$src_path" ]]; then
            echo -e "  ${RED}❌ Origem não encontrada: $src_path${RESET}"
            continue
        fi

        if [[ ! -d "$dest_path" ]]; then
            echo -e "  ${YELLOW}⚠️  $folder_name — destino não existe (nunca sincronizado)${RESET}"
            continue
        fi

        local diff_count
        diff_count=$(rsync -azn --delete "$src_path/" "$dest_path/" 2>/dev/null | grep -c "^>f" || echo "0")

        if [[ "$diff_count" -eq 0 ]]; then
            echo -e "  ${GREEN}✅ $folder_name — em dia${RESET}"
        else
            echo -e "  ${YELLOW}⚠️  $folder_name — $diff_count arquivo(s) pendente(s)${RESET}"
        fi
    done
    echo ""
}

# --- Dispatcher ---
main() {
    local cmd="${1:-run}"
    shift || true

    case "$cmd" in
        run)        cmd_run "false" ;;
        --dry-run)  cmd_run "true" ;;
        status)     cmd_status ;;
        help|--help)
            echo ""
            echo -e "${BOLD}VibeDoCode — sync${RESET}"
            echo "  run         Sincroniza todas as pastas"
            echo "  --dry-run   Simulação sem executar"
            echo "  status      Mostra diferenças pendentes"
            echo ""
            ;;
        *)
            echo -e "${RED}❌ Subcomando desconhecido: $cmd${RESET}"
            exit 1
            ;;
    esac
}

main "$@"
