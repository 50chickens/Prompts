# Tool Calling — How It Works

## Overview

Tool calling (also called function calling) is a standard part of the OpenAI chat completions protocol. The ELRChatBot API advertises a set of named tools in its API responses. When a recruiter sends a message in open-webui, the LLM decides whether any of the available tools should be called to fulfil the request. If it decides yes, it tells open-webui which tool to call and with what arguments. open-webui sends that call back to the ELRChatBot API, which executes it and returns the result. The LLM then uses the result to compose its reply to the recruiter.

From the recruiter's perspective none of this is visible. They type a message and get a reply. The tool calls happen silently in the background.

---

## The Flow

```
Recruiter types message in open-webui
        ↓
open-webui sends message + list of available tools to ELRChatBot API (/v1/chat/completions)
        ↓
ELRChatBot API forwards to ChatGPT (with tool definitions included)
        ↓
ChatGPT responds with a tool_call (instead of a plain reply)
        ↓
ELRChatBot API returns the tool_call to open-webui
        ↓
open-webui invokes the named tool on the ELRChatBot API
        ↓
ELRChatBot API executes the tool (reads files, creates folders, calls ChatGPT, writes results)
        ↓
Result is returned to open-webui
        ↓
open-webui sends the result back to the LLM
        ↓
LLM composes a plain-language reply to the recruiter using the result
```

The ELRChatBot API is both the OpenAI-compatible endpoint and the tool executor. It sits between open-webui and ChatGPT and handles both sides of the tool-calling exchange.

---

## Local File Access

The ELRChatBot API runs on the same Windows machine as the recruiter's data. This is the key advantage of this architecture over using ChatGPT directly or a cloud-hosted API.

When a tool is called, the ELRChatBot API can:
- Read files from `C:\git\internal\LinkedIn\data\` directly — briefs, transcripts, constraints documents, research responses
- Write new files and folders to disk as part of workflow execution
- Scan a folder the recruiter points to (e.g. a folder of PDFs or Word documents) and extract relevant content before sending anything to ChatGPT

The recruiter never needs to upload files or paste content. They give the system a folder path (or the system already knows where the assignment data lives) and the API does the reading. This is only possible because the API runs locally alongside the data.

---

## What Tool Calling Can Do

- Create assignment folder structures on disk
- Read and parse local documents (text, markdown, Word) to extract candidate constraints
- Read and write constraints files, research responses, filtered company lists, and LinkedIn search criteria
- Call ChatGPT with a composed request and save the response
- Return structured results (company lists, search strings) to the LLM for display in the chat
- Report the status of an assignment (which phases have been completed)

---

## Limitations

**The LLM decides when to call a tool — it cannot be forced.**
If the recruiter's message is ambiguous or too short, the LLM may reply conversationally instead of calling a tool. Well-written slash-command prompts and a clear system prompt reduce this problem significantly by giving the LLM enough context to make the right decision.

**Tool calls are sequential by default.**
Each tool call is one round-trip. A multi-step workflow (create assignment, read materials, populate constraints) requires either chaining multiple tool calls across turns or consolidating the steps into a single tool that the API orchestrates internally. The ELRChatBot API should consolidate where possible so the recruiter does not wait through multiple visible steps.

**open-webui must support tool calling on the connected model.**
open-webui passes tool definitions to the model only if the model supports function calling. The models exposed in open-webui must be ones that support this (e.g. gpt-4.1, gpt-4o) — models that do not support function calling will ignore the tool definitions and reply in plain text only.

**File paths must be within the known data root.**
The API should not accept arbitrary file paths from the LLM. Tool inputs that reference file paths must be validated against the known data root (`C:\git\internal\LinkedIn\data\`) to prevent the LLM from being manipulated into reading or writing files outside the expected scope.

**open-webui's own Python Functions system is separate and not used here.**
open-webui has a client-side Python scripting feature also called Functions. This runs inside the open-webui container and cannot access the host file system. It is not the same as the OpenAI tool-calling protocol and is not used for this workflow. All tool execution goes through the ELRChatBot API.

---

## Why This Architecture Works for ELR

The recruiter's documents, the assignment data, and the ELRChatBot API are all on the same machine. open-webui is a container on that same machine. The tool-calling flow never leaves the local network. ChatGPT only ever sees text content — extracted and sanitised by the API — not raw file paths or internal system details. The recruiter interacts only with the chat interface.

---

## How C# Integrates With Tool Calling

Tool calling does not have a "dotnet" or "assembly" mode — it is purely a JSON protocol over HTTP. The form a tool takes is:

1. A JSON schema definition advertised in the API response describing the tool's name, description, and parameters
2. An HTTP endpoint in the ELRChatBot API that accepts the tool call and returns a result

The ELRChatBot API is a standard ASP.NET Core application. Every tool is simply a C# method wired to an HTTP route. There is no special runtime, no COM interop, no assembly loading. The full .NET ecosystem is available inside those methods — file I/O, document parsing, calling OpenAI, anything.

**The integration path is:**
- Tool schema (name, description, parameters) is returned as part of the `/v1/chat/completions` response so the LLM knows what tools exist
- When the LLM chooses to call a tool, open-webui POSTs to the ELRChatBot API with the tool name and arguments
- The ELRChatBot API routes that POST to the corresponding C# method and returns the result as JSON
- The result goes back to the LLM which uses it to compose its reply

**What this means in practice:**
- Any workflow logic that can be written in C# can become a tool — reading Word documents, parsing PDFs, scanning folders, generating structured search queries, writing files
- Existing C# libraries (e.g. DocumentFormat.OpenXml for Word files, PdfPig for PDFs) can be used inside tool implementations without any wrapping or scripting layer
- There is no need to call `dotnet` as a subprocess or load arbitrary assemblies at runtime — the logic is compiled directly into the ELRChatBot API and runs in-process
- PowerShell scripts and external executables are explicitly not used — all logic that was previously in scripts is re-implemented as C# inside the API

**What tool calling cannot do natively with C#:**
- It cannot dynamically load or execute arbitrary .NET assemblies at runtime without being explicitly built to do so — and this should not be needed; all tools are defined at compile time
- It cannot run C# scripts (`.csx`) or Roslyn-compiled code on the fly — again, not needed; tools are pre-built methods
- The tool execution is synchronous from the LLM's perspective — long-running operations (e.g. scanning a large folder) will block the response until complete; keep tool operations fast or chunk them

**Summary:** C# integrates with tool calling by being the HTTP server that handles tool invocations. The tool definition is metadata; the implementation is ordinary C# code in the ELRChatBot API. No special dotnet integration mechanism is required beyond a standard ASP.NET Core controller.

---

## open-webui Tool-Calling Mechanisms

open-webui has four distinct mechanisms that can execute logic during a conversation. They differ significantly in where they run, what they can do, and how they integrate with C#.

---

### 1. OpenAI Function Calling (via the connected API)

This is what the ELRChatBot uses. open-webui passes tool definitions included in the API response to the LLM. When the LLM decides to call a tool, open-webui sends an HTTP POST back to the connected API with the tool name and arguments. The API executes the logic and returns a result.

**What it can do:** Anything the ELRChatBot API can do in C# — file I/O, document parsing, calling OpenAI, writing data. No restrictions from open-webui's side.
**What it cannot do:** It cannot run arbitrary shell commands or external processes directly from open-webui. All execution is delegated to the API server.
**Host access:** Yes — the ELRChatBot API runs on the host machine with full access to the filesystem.
**Suitable for ELR:** Yes — this is the primary mechanism.

---

### 2. open-webui Functions (Python, runs inside the container)

open-webui has its own Python scripting system under Admin Panel → Functions. These are Python scripts that run inside the open-webui Docker container. There are three sub-types:

- **Filter Functions** — intercept and modify messages before they reach the LLM or before the response is shown
- **Action Functions** — add clickable buttons to messages in the chat UI
- **Tool Functions** — appear as callable tools in the same way as API tools above, but executed in Python inside the container

Tool Functions can technically run shell commands via Python's `subprocess` module, but they run inside the open-webui Linux container — not on the Windows host. They have no access to `C:\git\internal\LinkedIn\data\` or any host filesystem paths.

**What it can do:** Python logic, HTTP calls to other services, subprocess calls to whatever is installed in the container.
**What it cannot do:** Access host files, run Windows commands, call C# assemblies.
**Host access:** No — container only.
**Suitable for ELR:** Not for file-based workflow steps. Could be used for lightweight stateless tasks (e.g. formatting output) but should not be the primary tool execution mechanism.

---

### 3. open-webui Pipelines (separate Python server)

Pipelines is an optional companion server distributed by the open-webui team. It runs as a separate container and connects to open-webui as if it were an OpenAI-compatible API. Pipeline scripts are Python and run in the Pipelines container.

Pipelines can make outbound HTTP calls to any URL — including the ELRChatBot API on localhost. This makes them a useful middleware layer if needed, but for this project they add complexity without benefit since the ELRChatBot API already serves this role directly.

**What it can do:** Python HTTP calls, text transformation, routing between multiple models.
**Host access:** No — separate container. Can call the host API via HTTP.
**Suitable for ELR:** Not needed. The ELRChatBot API already provides equivalent capability more directly.

---

### 4. MCP (Model Context Protocol) Servers

open-webui supports connecting MCP servers. MCP is an open protocol for exposing tools and resources to LLMs. An MCP server can be written in any language and run anywhere — including as a Windows process on the host. open-webui connects to it over stdio or HTTP and the MCP server's tools appear in the chat alongside API tools.

An MCP server written in C# and running as a Windows process on the host would have full access to the filesystem and could execute any .NET logic. This is a viable alternative or complement to the ELRChatBot API for exposing tools, but requires running and managing an additional process.

**What it can do:** Anything the MCP server process can do — in C#, that means full .NET.
**Host access:** Yes, if the MCP server runs on the host.
**Suitable for ELR:** Possible, but the ELRChatBot API already plays this role via OpenAI function calling. MCP could be considered later if the tool surface grows significantly.

---

### Summary

| Mechanism | Runs On | Host File Access | C# Support | Use for ELR |
|---|---|---|---|---|
| OpenAI Function Calling (via ELRChatBot API) | Windows host | Yes | Yes (native) | Primary |
| open-webui Functions (Python) | open-webui container | No | No | Not suitable |
| Pipelines | Pipelines container | No | Via HTTP only | Not needed |
| MCP Server | Anywhere (incl. host) | Yes if on host | Yes (as separate process) | Future option |

The ELRChatBot API via OpenAI function calling is the right choice. It runs on the host, is written in C#, has direct filesystem access, and requires no additional processes or containers.

---

### Running binaries inside open-webui (e.g. pwsh)

**Short answer: you can call binaries that exist in the open-webui container, but pwsh is not in that container — it is in the ELRChatBot API container.**

open-webui's Python Tool Functions use Python's `subprocess` to run shell commands. Those commands run inside the `ghcr.io/open-webui/open-webui:main` container — a Python/Node environment with no PowerShell installed. So `pwsh -Command "Write-Host 'hello'"` would fail with "command not found" because pwsh does not exist there.

The ELRChatBot API container (`mcr.microsoft.com/dotnet/aspnet:9.0-alpine`) is where pwsh is installed. But open-webui's Python Functions have no connection to that container — they only know about the open-webui container's own filesystem and processes.

**The three realistic paths if you want to run pwsh or similar commands:**

1. **Via the ELRChatBot API (recommended)** — The C# API can call `Process.Start("pwsh", ...)` from within the API container since pwsh is installed there, or more cleanly, any logic previously in a PowerShell script can be re-implemented directly in C#. The ELRChatBot API is the right place for this — it has pwsh available and runs on the host (via the volume-mounted bin folder).

2. **Via a Python Tool Function calling the ELRChatBot API over HTTP** — A Tool Function can make an HTTP call to `http://host.docker.internal:5000/v1/tools/...` which reaches the ELRChatBot API on the host. The API then runs any C# or pwsh logic it needs. This is indirection through two layers and is not needed given that OpenAI function calling already does this directly.

3. **By installing pwsh into the open-webui container** — You could extend the open-webui Docker image with `RUN apt-get install -y powershell` and then a Tool Function could call it via subprocess. This works but means maintaining a custom open-webui image and you still have no access to the host filesystem from inside the container.

**Conclusion:** Do not try to run pwsh from within open-webui's Python Functions for this workflow. The ELRChatBot API already has pwsh available and has host file access. Any command execution belongs there, invoked via OpenAI function calling.

---

### open-webui base image and adding dotnet / pwsh

**Base image:** The open-webui runtime container is `python:3.11.14-slim-bookworm` — Debian 12 (Bookworm) slim. The frontend is built from `node:22-alpine3.20` but that stage is discarded; only the Bookworm Python image runs at runtime.

**How hard is it to add dotnet and pwsh?**

Not very hard for a one-off — Debian Bookworm is one of the most straightforward Linux distributions to install both on. Microsoft publishes official apt repositories for both the .NET runtime/SDK and PowerShell that target Debian directly. The steps would be added as a new `FROM ... AS final` layer on top of the open-webui build, or as extra `RUN apt-get` lines in a derived `Dockerfile` that uses `FROM ghcr.io/open-webui/open-webui:main` as its base.

**What you get:**
- pwsh is available inside the open-webui container as `/usr/bin/pwsh`
- Python Tool Functions can call `subprocess.run(["pwsh", "-Command", "..."])` successfully
- dotnet CLI and any published .NET assemblies can be executed from within the container

**What you still don't get:**
- Host filesystem access — the container is still isolated from `C:\git\internal\LinkedIn\data\`. Any pwsh or dotnet code running inside open-webui can only see the container's own filesystem unless additional volume mounts are added.
- If you add the same volume mounts that the ELRChatBot API already has (i.e. mount `data\` into the open-webui container as well), then Tool Functions calling pwsh or dotnet inside open-webui *could* read and write host files.

**Maintenance cost:**
- You own the Dockerfile and must rebuild and re-tag the image whenever open-webui releases an update. The official `ghcr.io/open-webui/open-webui:main` tag auto-updates; a derived image does not.
- dotnet and pwsh add roughly 400–600 MB to the image size.

**Verdict:** It is feasible and not complex to implement. Whether it is worth the maintenance overhead depends on whether there is a genuine need to run .NET or pwsh logic inside the open-webui container specifically — which there currently is not, given that the ELRChatBot API already handles all of that on the host. If the ELRChatBot API were ever retired or moved to a different machine, this would become a more attractive option.


