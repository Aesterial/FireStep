<h1 align="center">FireStep</h1>

<p align="center">
  Короткий 3D-MVP на <code>Godot 4.6.2 Standard</code> про действия оператора при признаках возгорания на промышленном объекте.
</p>

<p align="center">
  <a href="https://github.com/Aesterial/FireStep">GitHub</a> ·
  <a href="./docs/TEST_PLAN.md">Test Plan</a> ·
  <a href="./docs/ASSETS.md">Assets</a> ·
  <a href="./docs/ASSET_PIPELINE.md">Asset Pipeline</a>
</p>

<p align="center">
  <a href="https://github.com/Aesterial/FireStep/actions/workflows/ci.yml">
    <img src="https://github.com/Aesterial/FireStep/actions/workflows/ci.yml/badge.svg?branch=master" alt="CI status" />
  </a>
</p>

---

## О проекте

**FireStep** собран как компактный учебный тренажер с одним цельным сценарием:
игрок проходит брифинг, реагирует на тревожную ситуацию в основном цехе, отключает резервный генератор в соседнем модуле и завершает эвакуацию на пункте сбора.

Текущий MVP уже включает:

- маршрут `Briefing -> Main -> SecondaryGenerator -> Evacuation -> Debrief`;
- промышленное 3D-окружение на встроенных примитивах Godot и локальных `Kenney` ассетах;
- русскоязычный HUD с objective/hint/banner/feedback;
- сценарные ошибки с провалом и финальный разбор результатов;
- headless-проверку проекта через `GitHub Actions`.

---

## Сценарий

1. В `Briefing` игрок получает вводную и запускает тренировку.
2. В `Main` нужно остановить аварийный модуль, отойти в safe zone и зафиксировать вызов помощи.
3. После выхода из цеха открывается `SecondaryGenerator`, где требуется отключить `GEN-02`.
4. В `Evacuation` игрок следует по маршруту к пункту сбора и подтверждает завершение эвакуации.
5. В `Debrief` показываются итоговый статус и ключевые выводы по действиям игрока.

---

## Технологический профиль

| Направление | Инструменты |
|-------------|-------------|
| Engine | `Godot 4.6.2 Standard` |
| Language | `GDScript` |
| Physics | `Jolt Physics` |
| UI | built-in `Control` nodes + runtime skinning |
| Delivery | `GitHub Actions` + headless validation |

---

## Запуск

1. Установить `Godot 4.6.2 Standard`.
2. Открыть проект через `project.godot`.
3. Запустить игру через `F5` или стартовать сцену `res://scenes/Briefing.tscn`.

### Управление

| Действие | Клавиши |
|----------|---------|
| Движение | `W`, `A`, `S`, `D` |
| Осмотр | `Mouse` |
| Взаимодействие | `E` |
| Быстрый шаг | `Shift` |
| Освободить / вернуть мышь | `Esc` |
| Перезапуск активной сцены | `R` |

---

## Проверка и CI

В репозитории настроен workflow [`CI`](https://github.com/Aesterial/FireStep/actions/workflows/ci.yml), который на `push`, `pull_request` и `workflow_dispatch`:

- скачивает фиксированный `Godot 4.6.2-stable` для Linux;
- импортирует ресурсы проекта в headless-режиме;
- выполняет smoke-check через headless-запуск;
- проверяет наличие обязательной документации.

Локально headless-проверку можно запускать тем же способом. Пример для Windows / Steam-установки:

```powershell
& "F:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --import
& "F:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --quit-after 1
```

Ручные сценарии проверки зафиксированы в [docs/TEST_PLAN.md](./docs/TEST_PLAN.md).

---

## Структура репозитория

```text
fire-step/
|-- assets/                 # модели, текстуры, UI и аудио
|-- docs/                   # тест-план, ассеты, asset pipeline
|-- scenes/                 # Briefing, Main, SecondaryGenerator, Evacuation, Debrief
|-- scripts/                # игровая логика сцен и сценарного состояния
`-- ui/                     # HUD и runtime UI-логика
```

---

## Ассеты и документация

| Файл | Назначение |
|------|------------|
| [`docs/ASSETS.md`](./docs/ASSETS.md) | Источники ассетов, лицензии и реальные пути использования |
| [`docs/ASSET_PIPELINE.md`](./docs/ASSET_PIPELINE.md) | Пояснения по замене и обновлению визуальных ресурсов |
| [`docs/TEST_PLAN.md`](./docs/TEST_PLAN.md) | Ручной сценарий проверки полного маршрута |
| [`AGENTS.md`](./AGENTS.md) | Ограничения по стеку и правила работы в проекте |

Проект остаётся маленьким demo-oriented MVP: без `C#`, `.NET`, плагинов, аддонов и внешних зависимостей вне локально подключённых ассетов.
