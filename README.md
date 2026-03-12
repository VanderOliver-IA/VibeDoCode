# VibeDoCode — Facilitando o Antigravity

> Extensão oficial para o **Antigravity (Gemini CLI)** que centraliza gestão de múltiplas contas Gmail, monitora cotas de LLMs, sincroniza pastas e gerencia agentes/skills.

[![Versão](https://img.shields.io/badge/versão-1.0.0-blue)](https://github.com/VanderOliver-IA/VibeDoCode/releases)
[![Licença](https://img.shields.io/badge/licença-MIT-green)](LICENSE)

---

## 🚀 Instalação

### Opção 1 — Via Gemini CLI (Recomendado)
```bash
gemini extensions install github.com/VanderOliver-IA/VibeDoCode
```

### Opção 2 — Script em uma linha
```bash
curl -fsSL https://raw.githubusercontent.com/VanderOliver-IA/VibeDoCode/main/install.sh | bash
```

### Pré-requisitos
- [Antigravity (Gemini CLI)](https://geminicli.com) instalado
- Node.js ≥ 18 (para o MCP Server)
- Python 3 (para o monitor de cotas)
- `rsync` (para sincronismo de pastas)

---

## ⚙️ Funcionalidades

### 🔐 Multi-Conta Gmail
Gerencie até **5 contas Google** no Antigravity com troca instantânea.

```bash
# Salvar conta atual no vault
/vibe-accounts save pessoal

# Ver todas as contas
/vibe-accounts list

# Trocar de conta
/vibe-accounts switch trabalho

# Ver conta ativa
/vibe-accounts status
```

**Como funciona:** O VibeDoCode mantém um vault seguro em `~/.vibedocode/vault/` com os tokens OAuth de cada conta. Trocar é um swap dos arquivos de credenciais do Antigravity — não requer `gcloud` CLI.

---

### 📊 Monitor de Cotas
Visualize o uso de cada LLM por conta em tempo real.

```bash
# Dashboard completo
/vibe-quota

# Cota de uma conta específica
/vibe-quota --conta trabalho
```

**Modelos monitorados:**
| Modelo | Limite Free |
|--------|-------------|
| Gemini 2.5 Pro | 50 req/dia |
| Gemini 2.0 Flash | 1500 req/dia |
| Gemini 1.5 Pro | 50 req/dia |
| Gemini 1.5 Flash | 1500 req/dia |

---

### 🔄 Sincronismo de Pastas
Sincronize pastas compartilhadas do workspace automaticamente.

```bash
# Sincronizar tudo
/vibe-sync

# Simular sem executar
/vibe-sync --dry-run

# Ver diferenças pendentes
/vibe-sync status
```

---

### 🧩 Gestão de Agentes & Skills
Inicialize e mantenha o Antigravity Kit em múltiplos projetos.

```bash
# Verificar status do .agent/
/vibe-agent status

# Iniciar .agent/ em novo projeto
/vibe-agent init

# Atualizar para última versão
/vibe-agent update

# Listar skills disponíveis
/vibe-skills list
```

---

## 📁 Estrutura do Vault

```
~/.vibedocode/
├── vault/
│   ├── accounts.json          ← Registro de contas
│   ├── pessoal/
│   │   ├── oauth_creds.json   ← Tokens OAuth
│   │   └── google_accounts.json
│   └── trabalho/
│       ├── oauth_creds.json
│       └── google_accounts.json
├── sync.log                   ← Log de sincronismos
├── quota.db                   ← Banco SQLite de cotas
└── sync-paths.json            ← Pastas configuradas para sync
```

---

## 🗺️ Roadmap

- [x] **v1.0** — Multi-conta Gmail + Estrutura base
- [x] **v1.0** — Monitor de cotas (SQLite local)
- [x] **v1.0** — Sincronismo de pastas (rsync)
- [x] **v1.0** — Gestão de agentes/skills
- [ ] **v1.1** — Monitor via Gemini API (uso real da API)
- [ ] **v1.1** — Modo watch para sync automático
- [ ] **v1.2** — Dashboard web local em localhost
- [ ] **v2.0** — Submissão para CLI Extensions Gallery oficial

---

## 🔧 Configuração Manual

### Pastas de Sync
Edite `~/.vibedocode/sync-paths.json`:
```json
{
  "paths": [
    "/caminho/para/Shared-Assets",
    "/caminho/para/Shared-Docs-APIs"
  ],
  "destination": "/home/usuario/Antigravity/Sync"
}
```

---

## 📄 Licença

MIT © [VanderOliver](https://github.com/VanderOliver-IA)
