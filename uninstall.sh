#!/usr/bin/env bash
# Полное удаление ИИ-помощника с Mac: приложение, папка помощника с токенами, Goose с настройками и историей,
# модель поиска, автоматизации, Python от установщика. После этого установка пойдёт с нуля.
#   bash uninstall.sh          — спросит подтверждение
#   bash uninstall.sh --yes    — без вопроса
# Не трогает: рабочую папку с вашими файлами (~/magnit-agent-workspace) и корпоративные сертификаты в связке ключей.
set -uo pipefail

if [[ "${1:-}" != "--yes" ]]; then
  echo "Будут удалены ИИ-помощник, Goose (приложение, настройки, история чатов), токены, модель поиска,"
  echo "базы знаний и автоматизации. Ваши файлы в ~/magnit-agent-workspace останутся."
  read -r -p "Удалить всё? Напечатайте «да»: " v
  [[ "$v" == "да" || "$v" == "yes" ]] || { echo "Отменено."; exit 0; }
fi

echo "Останавливаю Goose и помощника..."
osascript -e 'tell application "Goose" to quit' >/dev/null 2>&1
osascript -e 'tell application "ИИ-помощник" to quit' >/dev/null 2>&1
pkill -f "agent-c-agent-sdk/web.py" 2>/dev/null
pkill -f "shared/gateway" 2>/dev/null
sleep 2

echo "Автоматизации по расписанию..."
for plist in "$HOME"/Library/LaunchAgents/ru.magnit-agent.*.plist; do
  [[ -e "$plist" ]] || continue
  launchctl bootout "gui/$(id -u)" "$plist" 2>/dev/null || launchctl unload "$plist" 2>/dev/null
  rm -f "$plist"
done

echo "Приложения..."
rm -rf "/Applications/ИИ-помощник.app" "$HOME/Applications/ИИ-помощник.app"
rm -rf "/Applications/Goose.app" "$HOME/Applications/Goose.app"
command -v brew >/dev/null 2>&1 && { brew uninstall --cask block-goose >/dev/null 2>&1; brew uninstall block-goose-cli >/dev/null 2>&1; }

echo "Папка помощника (токены, окружения Python)..."
for d in "$HOME/ai-agent-local" "$HOME/Documents/ai-agent-local"; do
  [[ -f "$d/setup.sh" && ! -d "$d/.git" ]] && rm -rf "${d:?}"   # рабочую копию разработчика (git) не трогаем
done

echo "Данные помощника (модель поиска, базы знаний, журналы, настройки агентов)..."
rm -rf "$HOME/.magnit-agent"

echo "Goose: настройки, история чатов, данные приложения, навыки..."
rm -rf "$HOME/.config/goose" "$HOME/.local/share/goose" "$HOME/.local/state/goose" \
       "$HOME/Library/Application Support/Goose" "$HOME/Library/Logs/Goose" \
       "$HOME/Library/Caches/com.electron.goose" "$HOME/Library/Preferences/com.electron.goose.plist" \
       "$HOME/Library/Saved Application State/com.electron.goose.savedState"
for s in business-letter confluence-research data-report jira-task mail-digest meeting-protocol spec-routine; do
  rm -rf "$HOME/.agents/skills/$s"
done
security delete-generic-password -s goose -a secrets >/dev/null 2>&1   # токен LLM в связке ключей

echo "Команды и Python от установщика..."
rm -f "$HOME/.local/bin/magnit-goose" "$HOME/.local/bin/magnit-claude" "$HOME/.local/bin/magnit-agent" "$HOME/.local/bin/goose"
rm -rf "$HOME/.local/share/uv/python"            # Python, который ставил установщик через uv
rm -f "$HOME/.local/bin/uv" "$HOME/.local/bin/uvx"
rm -f /tmp/a.zip

echo
echo "Готово. ИИ-помощник и Goose удалены. Установить заново — командой из инструкции."
echo "Остались: ~/magnit-agent-workspace (ваши файлы) и корпоративные сертификаты в «Связке ключей», если их добавляли."
