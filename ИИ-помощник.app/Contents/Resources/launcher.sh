#!/bin/bash
# Запускается из «ИИ-помощник.app»: находит (или распаковывает из приложения) папку помощника и передаёт команду agentctl.sh.
RES="$(cd "$(dirname "$0")" && pwd)"
STATE="$HOME/.magnit-agent"; mkdir -p "$STATE"
ROOT="$(head -1 "$STATE/root" 2>/dev/null)"
if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
  ROOT="$HOME/ai-agent-local"
  for d in "$HOME/ai-agent-local" "$HOME/Documents/ai-agent-local"; do [[ -f "$d/setup.sh" ]] && { ROOT="$d"; break; }; done
fi
# Распаковать встроенный архив, если помощника ещё нет или в приложении версия новее (рабочую копию git не трогаем)
have="$(cat "$ROOT/VERSION" 2>/dev/null || echo 0)"; bundled="$(cat "$RES/VERSION" 2>/dev/null || echo 0)"
if [[ ! -d "$ROOT/.git" && -f "$RES/ai-agent-local.zip" ]] && { [[ ! -f "$ROOT/app/agentctl.sh" ]] || [[ "$bundled" -gt "$have" ]]; }; then
  tmp="$(mktemp -d)"
  if [[ -f "$ROOT/app/agentctl.sh" ]]; then
    : > "$ROOT/.update-pending" || exit 1
  fi
  if ! /usr/bin/ditto -x -k "$RES/ai-agent-local.zip" "$tmp" ||
     ! mkdir -p "$ROOT" || ! /usr/bin/rsync -a --exclude=VERSION "$tmp/ai-agent-local/" "$ROOT/" ||
     ! cp "$tmp/ai-agent-local/VERSION" "$ROOT/VERSION"; then
    rm -rf "${tmp:?}"
    echo "Не удалось распаковать новую версию помощника." >&2
    exit 1
  fi
  rm -rf "${tmp:?}"
  /usr/bin/xattr -dr com.apple.quarantine "$ROOT" 2>/dev/null
fi
[[ -f "$ROOT/app/agentctl.sh" ]] || { echo "Не найдена папка помощника: $ROOT" >&2; exit 1; }
echo "$ROOT" > "$STATE/root"
MAGNIT_ROOT="$ROOT" exec /bin/bash "$ROOT/app/agentctl.sh" "$@"
