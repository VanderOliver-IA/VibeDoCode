#!/usr/bin/env python3
"""
VibeDoCode — quota.py
Monitor de cotas de uso dos LLMs do Gemini por conta.

Usa contador local (SQLite) para rastrear uso por sessão.
Futuro: integrar com Gemini API usage endpoint quando disponível.
"""

import json
import os
import sqlite3
import argparse
from datetime import datetime, date
from pathlib import Path

# --- Configuração ---
VAULT_DIR = Path.home() / ".vibedocode" / "vault"
ACCOUNTS_FILE = VAULT_DIR / "accounts.json"
DB_PATH = Path.home() / ".vibedocode" / "quota.db"
GEMINI_DIR = Path.home() / ".gemini"

# Limites free tier (requests por dia)
MODEL_LIMITS = {
    "gemini-2.5-pro":     {"requests": 50,   "label": "Gemini 2.5 Pro"},
    "gemini-2.0-flash":   {"requests": 1500, "label": "Gemini 2.0 Flash"},
    "gemini-1.5-pro":     {"requests": 50,   "label": "Gemini 1.5 Pro"},
    "gemini-1.5-flash":   {"requests": 1500, "label": "Gemini 1.5 Flash"},
}

# Cores ANSI
RESET  = "\033[0m"
BOLD   = "\033[1m"
RED    = "\033[0;31m"
GREEN  = "\033[0;32m"
YELLOW = "\033[1;33m"
CYAN   = "\033[0;36m"
GRAY   = "\033[0;90m"


def ensure_db():
    """Cria banco de dados SQLite de cotas se não existir."""
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS quota_usage (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            email     TEXT NOT NULL,
            model     TEXT NOT NULL,
            date      TEXT NOT NULL,
            requests  INTEGER DEFAULT 0,
            UNIQUE(email, model, date)
        )
    """)
    conn.commit()
    return conn


def get_active_email():
    """Retorna o email da conta ativa no Antigravity."""
    accounts_file = GEMINI_DIR / "google_accounts.json"
    if accounts_file.exists():
        with open(accounts_file) as f:
            data = json.load(f)
        return data.get("active", "desconhecido")
    return "nao configurado"


def get_saved_accounts():
    """Retorna lista de contas salvas no vault."""
    if not ACCOUNTS_FILE.exists():
        return []
    with open(ACCOUNTS_FILE) as f:
        data = json.load(f)
    return data.get("accounts", [])


def get_usage(conn, email, model_id):
    """Retorna o uso do dia para (email, model)."""
    today = date.today().isoformat()
    row = conn.execute(
        "SELECT requests FROM quota_usage WHERE email=? AND model=? AND date=?",
        (email, model_id, today)
    ).fetchone()
    return row[0] if row else 0


def progress_bar(used, total, width=20):
    """Gera barra de progresso ASCII."""
    pct = min(used / total, 1.0) if total > 0 else 0
    filled = int(pct * width)
    bar = "█" * filled + "░" * (width - filled)
    return bar, pct


def status_icon(pct):
    """Ícone baseado no percentual de uso."""
    if pct >= 0.90:
        return f"{RED}🔴{RESET}"
    elif pct >= 0.75:
        return f"{YELLOW}⚠️ {RESET}"
    return f"{GREEN}✅{RESET}"


def render_dashboard(accounts_to_show, conn, active_email):
    """Renderiza o dashboard de cotas."""
    print()
    print(f"{CYAN}{BOLD}📊 VibeDoCode — Monitor de Cotas{RESET}")
    print(f"{CYAN}{'━' * 56}{RESET}")

    if not accounts_to_show:
        print(f"\n  {YELLOW}Nenhuma conta salva no vault.{RESET}")
        print(f"  Use {BOLD}vibe-accounts save <nome>{RESET} para registrar contas.")
        print()
        # Mostra ao menos a conta ativa
        accounts_to_show = [{"email": active_email, "name": "ativa"}]

    for acc in accounts_to_show:
        email = acc.get("email", "?")
        name = acc.get("name", "?")
        is_active = (email == active_email)
        status_tag = f"{GREEN}[ATIVA]{RESET}" if is_active else f"{GRAY}[PRONTA]{RESET}"

        print(f"\n  {BOLD}📧 {email}{RESET}  {status_tag}  ({name})")
        print(f"  {'─' * 52}")

        for model_id, info in MODEL_LIMITS.items():
            label = info["label"]
            limit = info["requests"]
            used = get_usage(conn, email, model_id)
            bar, pct = progress_bar(used, limit, width=18)
            icon = status_icon(pct)
            pct_str = f"{pct*100:.0f}%"
            print(f"  {label:<22} {bar}  {used:>4}/{limit:<5} ({pct_str:>4})  {icon}")

    print()
    now = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    print(f"{CYAN}{'━' * 56}{RESET}")
    print(f"  {GRAY}🔄 Atualizado: {now}{RESET}")
    print(f"  {GRAY}💡 Use 'vibe-accounts switch <nome>' para trocar de conta.{RESET}")
    print()


def cmd_show(args):
    """Mostra o dashboard de cotas."""
    conn = ensure_db()
    active_email = get_active_email()
    accounts = get_saved_accounts()

    if args.conta:
        accounts = [a for a in accounts if a.get("name") == args.conta or a.get("email") == args.conta]
        if not accounts:
            print(f"{RED}❌ Conta '{args.conta}' não encontrada no vault.{RESET}")
            return

    render_dashboard(accounts, conn, active_email)
    conn.close()


def cmd_record(args):
    """Registra 1 uso de um modelo para a conta ativa (chamado internamente)."""
    conn = ensure_db()
    email = get_active_email()
    today = date.today().isoformat()
    model = args.model or "gemini-2.5-pro"

    conn.execute("""
        INSERT INTO quota_usage (email, model, date, requests)
        VALUES (?, ?, ?, 1)
        ON CONFLICT(email, model, date)
        DO UPDATE SET requests = requests + 1
    """, (email, model, today))
    conn.commit()
    conn.close()
    print(f"{GREEN}✅ Uso registrado: {model} para {email}{RESET}")


def main():
    parser = argparse.ArgumentParser(
        description="VibeDoCode — Monitor de Cotas de LLMs"
    )
    subparsers = parser.add_subparsers(dest="command")

    # show
    show_p = subparsers.add_parser("show", help="Exibe dashboard de cotas")
    show_p.add_argument("--conta", help="Filtrar por nome ou email da conta")
    show_p.set_defaults(func=cmd_show)

    # record (uso interno / MCP)
    rec_p = subparsers.add_parser("record", help="Registra 1 uso de modelo")
    rec_p.add_argument("--model", default="gemini-2.5-pro")
    rec_p.set_defaults(func=cmd_record)

    args = parser.parse_args()

    if not hasattr(args, "func"):
        # Default: show
        args.conta = None
        cmd_show(args)
        return

    args.func(args)


if __name__ == "__main__":
    main()
