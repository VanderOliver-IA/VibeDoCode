# VibeDoCode — Facilitando o Antigravity

> Extensão oficial para o Antigravity (Gemini CLI) que centraliza gestão de contas, monitoramento de cotas e automações do workspace.

---

## 🔐 Comandos Disponíveis

### /vibe-accounts — Gestão de Múltiplas Contas Gmail

Use este comando para gerenciar até 5 contas Google no Antigravity.

**Subcomandos:**
- `list` — Lista todas as contas salvas no vault com status (ativa/pronta/vazia)
- `switch <nome>` — Troca para a conta especificada (requer reiniciar o Antigravity)
- `add <email> <nome>` — Adiciona e salva uma nova conta no vault
- `remove <nome>` — Remove conta do vault
- `status` — Mostra qual conta está ativa agora
- `save` — Salva os tokens da conta atual no vault sob um nome

**Exemplos de uso:**
```
/vibe-accounts list
/vibe-accounts switch trabalho
/vibe-accounts add meu@gmail.com pessoal
/vibe-accounts status
```

**Como funciona:**
O sistema usa um vault seguro em `~/.vibedocode/vault/` que armazena os tokens OAuth de cada conta separadamente. Trocar de conta é um swap de arquivos de credenciais + atualização do google_accounts.json.

---

### /vibe-quota — Monitor de Cotas

Monitora o uso de cada LLM (Gemini 2.5 Pro, Flash, etc.) por conta.

**Subcomandos:**
- `show` — Dashboard completo de todas as contas
- `--conta <nome>` — Cota de uma conta específica

---

### /vibe-sync — Sincronismo de Pastas

Sincroniza as pastas compartilhadas do workspace.

**Subcomandos:**
- `run` — Sincroniza todas as pastas mapeadas
- `status` — Mostra diferenças pendentes
- `--dry-run` — Simula sem executar

---

### /vibe-agent — Gestão do .agent/

Gerencia agentes e skills do Antigravity Kit.

**Subcomandos:**
- `init` — Inicializa estrutura `.agent/` em novo projeto
- `status` — Verifica integridade do `.agent/` atual
- `update` — Atualiza para a última versão do repositório

---

## 🛡️ Comportamento Padrão

Quando o usuário mencionar troca de conta, autenticação, ou login com Google:
1. Verificar se o vault existe: `~/.vibedocode/vault/`
2. Listar contas disponíveis com `/vibe-accounts list`
3. Orientar o switch com `/vibe-accounts switch <nome>`
4. Lembrar que o Antigravity precisa ser reiniciado após a troca

Quando o usuário mencionar cota, limite, quota ou "acabou o crédito":
1. Rodar `/vibe-quota show` para diagnóstico rápido
2. Sugerir troca para conta com mais cota disponível

---

## 📁 Estrutura do Vault

```
~/.vibedocode/
├── vault/
│   ├── accounts.json          ← Registro de contas (sem tokens)
│   ├── <nome>/
│   │   ├── oauth_creds.json   ← Tokens OAuth da conta
│   │   └── google_accounts.json ← Estado de conta Google
│   └── ...
├── sync.log                   ← Log de sincronismos
└── config.json                ← Configurações globais do VibeDoCode
```
