# Ассеты И Источники

## Используется В Этом Билде

### Встроенные возможности Godot

- примитивы `BoxMesh`, `CylinderMesh`, `SphereMesh`;
- 3D-узлы `StaticBody3D`, `Area3D`, `CollisionShape3D`, `OmniLight3D`, `DirectionalLight3D`, `Label3D`;
- UI-узлы `Control`, `PanelContainer`, `Label`, `Button`, `ColorRect`, `CanvasLayer`;
- встроенный импорт `glb`, `png`, `ogg`, `ttf`.

### Внешние ассеты

1. `Kenney - City Kit (Industrial)`
   Источник: `https://kenney.nl/assets/city-kit-industrial`
   Лицензия: `CC0`
   Использование в проекте:
   - `assets/models/detail-tank.glb`
   - `assets/models/chimney-small.glb`
   - `assets/models/chimney-medium.glb`
   - `assets/textures/variation-a.png`
   - `assets/textures/variation-b.png`
   - `assets/textures/variation-c.png`

2. `Kenney - UI Pack`
   Источник: `https://kenney.nl/assets/ui-pack`
   Лицензия: `CC0`
   Использование в проекте:
   - `assets/ui/fonts/Kenney Future.ttf`
   - `assets/ui/fonts/Kenney Future Narrow.ttf`
   - `assets/ui/textures/button_green.png`
   - `assets/ui/textures/button_red.png`
   - `assets/ui/textures/button_grey.png`
   - `assets/ui/textures/button_blue.png`
   - `assets/ui/textures/panel_outline.png`
   - `assets/ui/textures/divider.png`
   - `assets/ui/sounds/click-a.ogg`

3. `Kenney - Impact Sounds`
   Источник: `https://kenney.nl/assets/impact-sounds`
   Лицензия: `CC0`
   Использование в проекте:
   - `assets/audio/footsteps/footstep_concrete_000.ogg`
   - `assets/audio/footsteps/footstep_concrete_001.ogg`
   - `assets/audio/footsteps/footstep_concrete_002.ogg`
   - `assets/audio/footsteps/footstep_concrete_003.ogg`
   - `assets/audio/footsteps/footstep_concrete_004.ogg`

## Локальные Исходники В Репозитории

- `icon.svg` — иконка проекта, уже присутствовавшая в репозитории.
- `case.pdf` — описание кейса и сценарных ограничений.
- `kenney_city-kit-industrial_1.0/` — локальная копия industrial-пака Kenney, из которой были взяты модели и surface-текстуры.

## Что Изменилось Относительно Базовой Версии

- UI теперь использует текстурированные кнопки и панели вместо голых `StyleBoxFlat`.
- Во всех игровых сценах добавлены реальные внешние ассеты, а не только примитивные коробки.
- Для шага игрока подключены concrete footstep-звуки.

## Примечание

Если в проект будут добавляться новые внешние модели, текстуры или звуки, их нужно дописывать сюда отдельным списком с источником, лицензией и реальными путями использования.
