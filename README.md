# CorePost iOS

Нативный SwiftUI-клиент для iPhone с ручной настройкой серверного адреса, локальным хранением секретов и сценарием блокировки/восстановления доступа.

## Что есть сейчас

- адрес сервера вводится пользователем, его можно изменить или полностью удалить
- `emergencyId`, `panic secret` и административный токен хранятся отдельно от обычных настроек
- доступны проверка соединения, создание профиля устройства, блокировка, подтверждение блокировки и восстановление доступа
- demo-flow воспроизводится через `xcodebuild` и iOS Simulator

## Сборка

```bash
xcodegen generate
xcodebuild \
  -project CorePostMobileIOS.xcodeproj \
  -scheme CorePostMobileIOS \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build
```

## Demo на симуляторе

Перед запуском укажите адрес сервера и административный токен через переменные окружения.

```bash
export DEMO_SERVER_ADDRESS='http://...'
export DEMO_ADMIN_TOKEN='...'
./scripts/run_demo.sh
```

Скрипт:

- пересобирает проект через `xcodegen`
- запускает UI-demo на iOS Simulator
- сохраняет видео в `docs/demo/video/corepost-ios-demo.mp4`
- выгружает скриншоты этапов в `docs/demo/screenshots/`

## Артефакты demo

Видео:

- `docs/demo/video/corepost-ios-demo.mp4`

Скриншоты:

![Onboarding](docs/demo/screenshots/01-onboarding.png)
![Настройки](docs/demo/screenshots/02-settings.png)
![Профиль готов](docs/demo/screenshots/03-dashboard-ready.png)
![Ожидание подтверждения](docs/demo/screenshots/04-pending-lock.png)
![Устройство заблокировано](docs/demo/screenshots/05-locked.png)
![Доступ восстановлен](docs/demo/screenshots/06-recovered.png)

## Release flow

1. Собрать архив в Xcode или через `xcodebuild archive`.
2. Экспортировать `.ipa` с локальными настройками подписи.
3. Загрузить `.ipa` в GitHub Releases.

В проекте нет зашитого серверного адреса: для обычной работы и для demo он передаётся только пользователем или через переменные окружения во время тестового запуска.
