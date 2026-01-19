# ProcessLeash — CPU limiter for macOS

Menu-bar SwiftUI app that limits CPU usage of selected processes via duty-cycle `SIGSTOP/SIGCONT`. Works for user processes (no privileged helper).

## Requirements
- macOS 13+
- Xcode or Command Line Tools (Swift toolchain 6+)

## Build
1. Local: `./scripts/build_dmg.sh` — builds release, produces `ProcessLeash.app` (LSUIElement=YES) and packs `dist/ProcessLeash.dmg`.
2. Quick run without dmg: `swift build -c release` then `.build/release/ProcessLeash`.
3. Update the bundle id in `Packaging/Info.plist` before shipping if needed.

## Download
- [Download the latest build](https://github.com/avyakunin/ProcessLeash/releases/latest/download/ProcessLeash.dmg) — artifact from GitHub Releases (built locally via `./scripts/build_dmg.sh`).
- Quick run without dmg: see the build step above.

## CI
GitHub Actions (macOS 13) runs `swift build -c release` and `swift test` on pushes and PRs (`.github/workflows/ci.yml`).

## Contributing
See CONTRIBUTING.md and CODE_OF_CONDUCT.md before sending a PR.

## Changelog
Current changes are in CHANGELOG.md. GitHub Releases host published dmgs.

## Implementation notes
- CPU limiting is approximate (especially for multi-threaded workloads).
- `SIGSTOP/SIGCONT` can cause audio/network/lock hiccups.
- Throttling only works for processes of the current user; other PIDs require a privileged helper (SMAppService/XPC).

### Key files
- `Sources/ProcessLeash/CPULimiter.swift` — duty-cycle throttling with Swift Concurrency.
- `Sources/ProcessLeash/ProcessLeashApp.swift` — menu-bar UI, process list, limit sliders.
- `Packaging/Info.plist` — LSUIElement=YES, bundle metadata.
- `Packaging/AppIcon.icns` — app icon (placeholder).
- `scripts/build_dmg.sh` — release build and dmg packaging (with Applications symlink).

Additional notes kept from earlier discussions: watchdog/auto-SIGCONT ideas, migration to SMAppService daemon + XPC for root-level throttling (see git history for context).

---

# ProcessLeash — ограничитель ЦП для macOS

Меню-барное SwiftUI-приложение, которое ограничивает CPU-потребление выбранных процессов через duty-cycle `SIGSTOP/SIGCONT`. Работает для пользовательских процессов (без привилегированного helper).

## Требования
- macOS 13+
- Xcode или Command Line Tools (Swift toolchain 6+)

## Как собрать
1. Локально: `./scripts/build_dmg.sh` — собирает release, формирует `ProcessLeash.app` (LSUIElement=YES) и упаковывает в `dist/ProcessLeash.dmg`.
2. Быстрый запуск без dmg: `swift build -c release` и затем `.build/release/ProcessLeash`.
3. При необходимости обнови bundle id в `Packaging/Info.plist` перед сборкой/дистрибуцией.

## Скачать
- [Скачать последнюю сборку](https://github.com/avyakunin/ProcessLeash/releases/latest/download/ProcessLeash.dmg) — артефакт из GitHub Releases (собирается локально через `./scripts/build_dmg.sh`).
- Быстрый запуск без dmg см. выше.

## CI
GitHub Actions (macOS 13) гоняет `swift build -c release` и `swift test` на пушах и PR (`.github/workflows/ci.yml`).

## Контрибьютинг
Смотри CONTRIBUTING.md и CODE_OF_CONDUCT.md перед отправкой PR.

## История изменений
Актуальный список изменений — в CHANGELOG.md. Releases на GitHub содержат опубликованные dmg.

## Детали реализации
- Ограничение ЦП приближённое (особенно на многопоточных задачах).
- При `SIGSTOP/SIGCONT` возможны фризы/таймауты в аудио/сети/локах.
- Троттлить можно только процессы текущего пользователя; для чужих PID нужен privileged helper (SMAppService/XPC).

### Основные файлы
- `Sources/ProcessLeash/CPULimiter.swift` — duty-cycle троттлинг с Swift Concurrency.
- `Sources/ProcessLeash/ProcessLeashApp.swift` — меню-бар UI, список процессов, ползунки лимита.
- `Packaging/Info.plist` — LSUIElement=YES, данные бандла.
- `Packaging/AppIcon.icns` — иконка приложения (placeholder).
- `scripts/build_dmg.sh` — сборка release и упаковка в dmg (с приложением и ссылкой Applications внутри образа).

Дополнительно в `README` из переписки сохранены советы: watchdog/auto-SIGCONT, переход на SMAppService daemon + XPC для root-троттлинга. (Исторический контент доступен в git истории при необходимости.)
<!-- Copyright (C) 2026 ProcessLeash contributors -->
