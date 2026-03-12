#!/usr/bin/env bash
# =============================================================================
# VibeDoCode — agent-manager.sh
# Gestão do Antigravity Kit (.agent/) entre projetos
# =============================================================================

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
GRAY='\033[0;90m'
RESET='\033[0m'

# Repositório fonte do Antigravity Kit
KIT_SOURCE="/home/vanderoliver/Antigravity/Projetos/01 - Em Andamento/13-Extensao Antigravity/.agent"

banner() {
    echo ""
    echo -e "${CYAN}${BOLD}🧩 VibeDoCode — Gestão de Agentes & Skills${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# --- Comando: status ---
cmd_status() {
    banner
    local target="${1:-$(pwd)}"
    local agent_dir="$target/.agent"

    echo ""
    echo -e "  ${BOLD}Projeto:${RESET} $target"
    echo ""

    if [[ ! -d "$agent_dir" ]]; then
        echo -e "  ${RED}❌ Nenhum .agent/ encontrado neste projeto.${RESET}"
        echo -e "  Use ${BOLD}vibe-agent init${RESET} para inicializar."
        echo ""
        return
    fi

    local agents_count=0 skills_count=0 workflows_count=0

    [[ -d "$agent_dir/agents" ]]    && agents_count=$(ls "$agent_dir/agents/"*.md 2>/dev/null | wc -l) || true
    [[ -d "$agent_dir/skills" ]]    && skills_count=$(ls -d "$agent_dir/skills/"*/ 2>/dev/null | wc -l) || true
    [[ -d "$agent_dir/workflows" ]] && workflows_count=$(ls "$agent_dir/workflows/"*.md 2>/dev/null | wc -l) || true

    echo -e "  ${GREEN}✅ .agent/ encontrado${RESET}"
    echo -e "  ${BOLD}Agentes:${RESET}    $agents_count"
    echo -e "  ${BOLD}Skills:${RESET}     $skills_count"
    echo -e "  ${BOLD}Workflows:${RESET}  $workflows_count"

    # Verifica GEMINI.md
    if [[ -f "$target/GEMINI.md" ]]; then
        echo -e "  ${BOLD}GEMINI.md:${RESET}  ${GREEN}✅ presente${RESET}"
    else
        echo -e "  ${BOLD}GEMINI.md:${RESET}  ${YELLOW}⚠️  ausente${RESET}"
    fi

    echo ""
}

# --- Comando: init ---
cmd_init() {
    local target="${1:-$(pwd)}"
    banner

    echo ""
    echo -e "  ${BOLD}Inicializando .agent/ em:${RESET}"
    echo -e "  $target"
    echo ""

    if [[ ! -d "$KIT_SOURCE" ]]; then
        echo -e "  ${RED}❌ Kit source não encontrado: $KIT_SOURCE${RESET}"
        exit 1
    fi

    if [[ -d "$target/.agent" ]]; then
        echo -e "  ${YELLOW}⚠️  .agent/ já existe. Use 'vibe-agent update' para atualizar.${RESET}"
        echo ""
        return
    fi

    # Copia estrutura do kit
    cp -r "$KIT_SOURCE" "$target/.agent"
    echo -e "  ${GREEN}✅ .agent/ criado com sucesso!${RESET}"
    echo -e "  ${BOLD}Agentes, skills e workflows copiados.${RESET}"

    # Copia GEMINI.md se não existe no destino
    local kit_gemini
    kit_gemini=$(dirname "$KIT_SOURCE")/GEMINI.md
    if [[ -f "$kit_gemini" && ! -f "$target/GEMINI.md" ]]; then
        cp "$kit_gemini" "$target/GEMINI.md"
        echo -e "  ${GREEN}✅ GEMINI.md criado.${RESET}"
    fi

    echo ""
    echo -e "  ${CYAN}💡 Dica: Edite o GEMINI.md do projeto para customizar o comportamento.${RESET}"
    echo ""
}

# --- Comando: update ---
cmd_update() {
    local target="${1:-$(pwd)}"
    banner

    echo ""
    echo -e "  Atualizando .agent/ em: $target"
    echo ""

    if [[ ! -d "$target/.agent" ]]; then
        echo -e "  ${RED}❌ .agent/ não encontrado. Use 'vibe-agent init' primeiro.${RESET}"
        exit 1
    fi

    if [[ ! -d "$KIT_SOURCE" ]]; then
        echo -e "  ${RED}❌ Kit source não encontrado: $KIT_SOURCE${RESET}"
        exit 1
    fi

    # Atualiza com rsync preservando customizações locais
    rsync -az --exclude="*.local.*" "$KIT_SOURCE/" "$target/.agent/"

    echo -e "  ${GREEN}✅ .agent/ atualizado com sucesso!${RESET}"
    echo ""
}

# --- Comando: skills list ---
cmd_skills_list() {
    banner
    local agent_dir="${1:-$(pwd)}/.agent"

    echo ""
    echo -e "  ${BOLD}Skills disponíveis:${RESET}"
    echo ""

    if [[ ! -d "$agent_dir/skills" ]]; then
        echo -e "  ${RED}❌ Diretório skills não encontrado.${RESET}"
        return
    fi

    for skill_dir in "$agent_dir/skills"/*/; do
        local skill_name
        skill_name=$(basename "$skill_dir")
        local skill_desc=""

        if [[ -f "$skill_dir/SKILL.md" ]]; then
            skill_desc=$(grep -m1 "^description:" "$skill_dir/SKILL.md" 2>/dev/null | sed 's/description: //' | cut -c1-60 || echo "")
        fi

        echo -e "  ${GREEN}•${RESET} ${BOLD}$skill_name${RESET}"
        if [[ -n "$skill_desc" ]]; then
            echo -e "    ${GRAY}$skill_desc${RESET}"
        fi
    done
    echo ""
}

# --- Dispatcher ---
main() {
    local cmd="${1:-status}"
    shift || true

    case "$cmd" in
        status)      cmd_status "$@" ;;
        init)        cmd_init "$@" ;;
        update)      cmd_update "$@" ;;
        skills)
            local sub="${1:-list}"
            shift || true
            case "$sub" in
                list) cmd_skills_list "$@" ;;
                *) echo -e "${RED}❌ Subcomando desconhecido: $sub${RESET}" ;;
            esac
            ;;
        help|--help)
            echo ""
            echo -e "${BOLD}VibeDoCode — agent${RESET}"
            echo "  status [dir]    Verifica integridade do .agent/"
            echo "  init [dir]      Inicializa .agent/ no projeto"
            echo "  update [dir]    Atualiza .agent/ com versão mais recente"
            echo "  skills list     Lista todas as skills"
            echo ""
            ;;
        *)
            echo -e "${RED}❌ Subcomando desconhecido: $cmd${RESET}"
            exit 1
            ;;
    esac
}

main "$@"
