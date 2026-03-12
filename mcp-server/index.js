#!/usr/bin/env node
/**
 * VibeDoCode — MCP Server
 * Expõe tools de gestão de contas, cotas e workspace para o Antigravity.
 *
 * Compatível com: Model Context Protocol SDK v1.x
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { execSync, exec } from "child_process";
import { promisify } from "util";
import path from "path";
import { fileURLToPath } from "url";

const execAsync = promisify(exec);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SCRIPTS_DIR = path.join(__dirname, "..", "scripts");

// Helper para rodar scripts bash/python
async function runScript(script, args = []) {
  const scriptPath = path.join(SCRIPTS_DIR, script);
  const cmd = script.endsWith(".py")
    ? `python3 "${scriptPath}" ${args.join(" ")}`
    : `bash "${scriptPath}" ${args.join(" ")}`;

  try {
    const { stdout, stderr } = await execAsync(cmd, { timeout: 30000 });
    return { success: true, output: stdout || stderr };
  } catch (err) {
    return { success: false, output: err.message, stderr: err.stderr };
  }
}

// --- Cria o servidor MCP ---
const server = new McpServer({
  name: "vibedocode",
  version: "1.0.0",
});

// ====================================================
// TOOL: vibe_accounts_list
// ====================================================
server.tool(
  "vibe_accounts_list",
  "Lista todas as contas Gmail salvas no vault do VibeDoCode com status (ativa/pronta/vazia)",
  {},
  async () => {
    const result = await runScript("accounts.sh", ["list"]);
    return {
      content: [{ type: "text", text: result.output }],
    };
  }
);

// ====================================================
// TOOL: vibe_accounts_status
// ====================================================
server.tool(
  "vibe_accounts_status",
  "Mostra qual conta Gmail está ativa no Antigravity agora",
  {},
  async () => {
    const result = await runScript("accounts.sh", ["status"]);
    return {
      content: [{ type: "text", text: result.output }],
    };
  }
);

// ====================================================
// TOOL: vibe_accounts_switch
// ====================================================
server.tool(
  "vibe_accounts_switch",
  "Troca para outra conta Gmail salva no vault. Requer reiniciar o Antigravity após a troca.",
  {
    name: z.string().describe("Nome da conta no vault (ex: 'pessoal', 'trabalho')"),
  },
  async ({ name }) => {
    const result = await runScript("accounts.sh", ["switch", `"${name}"`]);
    return {
      content: [{ type: "text", text: result.output }],
    };
  }
);

// ====================================================
// TOOL: vibe_accounts_save
// ====================================================
server.tool(
  "vibe_accounts_save",
  "Salva os tokens OAuth da conta ativa no vault com um nome amigável",
  {
    name: z.string().describe("Nome para identificar esta conta (ex: 'pessoal', 'trabalho', 'finomde')"),
  },
  async ({ name }) => {
    const result = await runScript("accounts.sh", ["save", `"${name}"`]);
    return {
      content: [{ type: "text", text: result.output }],
    };
  }
);

// ====================================================
// TOOL: vibe_quota_show
// ====================================================
server.tool(
  "vibe_quota_show",
  "Exibe dashboard de uso de cotas de todos os modelos LLM por conta Gmail",
  {
    conta: z.string().optional().describe("Filtrar por nome da conta (opcional)"),
  },
  async ({ conta }) => {
    const args = conta ? ["show", "--conta", conta] : ["show"];
    const result = await runScript("quota.py", args);
    return {
      content: [{ type: "text", text: result.output }],
    };
  }
);

// ====================================================
// TOOL: vibe_sync_run
// ====================================================
server.tool(
  "vibe_sync_run",
  "Sincroniza as pastas compartilhadas do workspace Antigravity",
  {
    dry_run: z.boolean().optional().describe("Se true, mostra o que seria feito sem executar"),
  },
  async ({ dry_run }) => {
    const args = dry_run ? ["--dry-run"] : ["run"];
    const result = await runScript("sync.sh", args);
    return {
      content: [{ type: "text", text: result.output }],
    };
  }
);

// ====================================================
// TOOL: vibe_sync_status
// ====================================================
server.tool(
  "vibe_sync_status",
  "Verifica quais pastas compartilhadas têm arquivos pendentes de sincronismo",
  {},
  async () => {
    const result = await runScript("sync.sh", ["status"]);
    return {
      content: [{ type: "text", text: result.output }],
    };
  }
);

// ====================================================
// TOOL: vibe_agent_status
// ====================================================
server.tool(
  "vibe_agent_status",
  "Verifica a integridade e estatísticas do .agent/ no projeto atual",
  {
    project_path: z.string().optional().describe("Caminho do projeto (padrão: diretório atual)"),
  },
  async ({ project_path }) => {
    const args = project_path ? ["status", `"${project_path}"`] : ["status"];
    const result = await runScript("agent-manager.sh", args);
    return {
      content: [{ type: "text", text: result.output }],
    };
  }
);

// ====================================================
// TOOL: vibe_agent_init
// ====================================================
server.tool(
  "vibe_agent_init",
  "Inicializa a estrutura .agent/ do Antigravity Kit em um novo projeto",
  {
    project_path: z.string().optional().describe("Caminho do projeto onde inicializar (padrão: diretório atual)"),
  },
  async ({ project_path }) => {
    const args = project_path ? ["init", `"${project_path}"`] : ["init"];
    const result = await runScript("agent-manager.sh", args);
    return {
      content: [{ type: "text", text: result.output }],
    };
  }
);

// ====================================================
// TOOL: vibe_skills_list
// ====================================================
server.tool(
  "vibe_skills_list",
  "Lista todas as skills disponíveis no .agent/ do projeto atual",
  {},
  async () => {
    const result = await runScript("agent-manager.sh", ["skills", "list"]);
    return {
      content: [{ type: "text", text: result.output }],
    };
  }
);

// --- Inicia o servidor ---
const transport = new StdioServerTransport();
await server.connect(transport);
console.error("VibeDoCode MCP Server iniciado ✅");
