# 中国象棋 (Xiangqi) - Godot 4.6 开发计划

> 使用 Godot 4.6 + GDScript 开发的中国象棋游戏

## 项目概述

本项目旨在开发一个功能完整的中国象棋游戏，采用传统木纹风格的棋盘界面，支持双人对弈、悔棋、走棋记录等功能。

### 设计决策

| 设计项 | 选择 |
|--------|------|
| **棋盘风格** | 传统木纹风格 |
| **棋子字符** | 繁体字 (帥/將, 仕/士, 相/象, 馬, 車, 砲/炮, 兵/卒) |
| **走棋记录** | 中文记谱法 (炮二平五, 馬八進七) |
| **界面布局** | 棋盘居中 + 右侧UI面板 |

---

## 项目结构

```
D:/Godot/xiangqi/
├── project.godot
├── README.md
│
├── assets/                          # 游戏资源
│   ├── fonts/
│   │   └── chinese_font.ttf         # 支持中文字符的字体
│   ├── themes/
│   │   └── game_theme.tres          # 全局UI主题
│   └── audio/                       # [未来] 音效占位
│       └── .gitkeep
│
├── resources/                       # 自定义Resource定义
│   ├── piece_data.gd                # PieceData资源类
│   └── game_state.gd                # GameState资源 (用于存档)
│
├── scripts/                         # 核心游戏逻辑 (无Node依赖)
│   ├── constants.gd                 # 游戏常量和枚举
│   ├── board_logic.gd               # 棋盘状态管理
│   ├── move_validator.gd            # 各棋子走法验证
│   ├── check_detector.gd            # 将军/将死检测
│   ├── move_generator.gd            # 合法走法生成
│   └── game_rules.gd                # 胜负条件、回合管理
│
├── scenes/                          # 场景文件
│   ├── main.tscn                    # 主游戏场景 (入口)
│   ├── board/
│   │   ├── board.tscn               # 棋盘可视化组件
│   │   └── board.gd
│   ├── pieces/
│   │   ├── piece.tscn               # 棋子可视化组件 (可复用)
│   │   └── piece.gd
│   └── ui/
│       ├── game_ui.tscn             # 游戏UI覆盖层
│       ├── game_ui.gd
│       ├── move_history_panel.tscn  # 走棋历史显示
│       ├── move_history_panel.gd
│       ├── status_panel.tscn        # 回合/将军状态显示
│       └── status_panel.gd
│
├── autoload/                        # 单例脚本
│   ├── game_manager.gd              # 中央游戏协调器
│   └── event_bus.gd                 # 全局信号总线
│
└── tests/                           # [可选] 单元测试
    └── test_move_validation.gd
```

---

## 场景层级设计

### 主场景 (`main.tscn`)
```
Main (Node2D)
├── Board (Node2D)                   # 棋盘可视化 + 交互
│   ├── BoardBackground (Sprite2D)   # 木纹背景
│   ├── GridLines (Node2D)           # 使用 _draw() 绘制网格
│   ├── PalaceMarkers (Node2D)       # 九宫斜线
│   ├── RiverLabel (Label)           # "楚河  汉界" 文字
│   ├── Pieces (Node2D)              # 所有棋子实例容器
│   │   └── [Piece instances...]
│   └── MoveIndicators (Node2D)      # 合法走法高亮圆点
│       └── [Indicator instances...]
│
├── CanvasLayer (UI层)
│   └── GameUI (Control)
│       ├── MarginContainer
│       │   ├── VBoxContainer
│       │   │   ├── StatusPanel      # 回合显示
│       │   │   ├── MoveHistoryPanel # 走棋历史
│       │   │   └── ButtonContainer  # 按钮区
│       │   │       ├── NewGameButton
│       │   │       └── UndoButton
│       │   └── HSeparator
│       └── [Future: GameOverDialog]
│
└── AudioStreamPlayer               # [未来] 音效
```

### 棋子场景 (`piece.tscn`)
```
Piece (Area2D)                      # 用于点击检测
├── Background (Sprite2D)           # 圆形棋子背景
├── CharacterLabel (Label)          # 中文字符显示
└── CollisionShape2D                # 点击碰撞区域
```

---

## 架构设计

### 核心设计原则

1. **关注点分离**
   - **逻辑层** (`scripts/`): 纯GDScript类，无Node依赖，易于测试
   - **视觉层** (`scenes/`): Node节点负责渲染状态和处理输入
   - **协调层** (`autoload/`): 单例桥接逻辑与视觉

2. **基于信号的通信**
   - 使用 `EventBus` 单例进行解耦通信
   - 棋子发出信号 → GameManager处理 → UI更新

3. **数据驱动的棋子配置**
   - 使用 `Resource` 类定义棋子属性
   - 便于修改规则而无需改动代码

### 类架构图

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AUTOLOAD 单例                               │
├─────────────────────────────────────────────────────────────────────┤
│  EventBus              │  GameManager                               │
│  - piece_selected      │  - current_game: BoardLogic                │
│  - move_requested      │  - handle_piece_click()                    │
│  - move_executed       │  - handle_move_request()                   │
│  - turn_changed        │  - new_game()                              │
│  - check_detected      │  - undo_move()                             │
│  - game_over           │  - is_game_over: bool                      │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          逻辑层                                     │
├─────────────────────────────────────────────────────────────────────┤
│  BoardLogic                        │  MoveValidator                 │
│  - board[10][9]: PieceData         │  - validate_general()          │
│  - current_turn: Side              │  - validate_advisor()          │
│  - move_history: Array[Move]       │  - validate_elephant()         │
│  - get_piece_at(pos)               │  - validate_horse()            │
│  - move_piece(from, to)            │  - validate_chariot()          │
│  - undo_last_move()                │  - validate_cannon()           │
│                                    │  - validate_soldier()          │
├────────────────────────────────────┼────────────────────────────────┤
│  MoveGenerator                     │  CheckDetector                 │
│  - get_legal_moves(piece, pos)     │  - is_in_check(side)           │
│  - get_all_legal_moves(side)       │  - is_checkmate(side)          │
│  - filter_check_moves()            │  - is_stalemate(side)          │
│                                    │  - flying_general_check()      │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         视觉层                                      │
├─────────────────────────────────────────────────────────────────────┤
│  Board (Node2D)                    │  Piece (Area2D)                │
│  - draw_grid()                     │  - piece_data: PieceData       │
│  - spawn_pieces()                  │  - update_visual()             │
│  - highlight_moves()               │  - _on_input_event()           │
│  - animate_move()                  │  - animate_capture()           │
├────────────────────────────────────┼────────────────────────────────┤
│  GameUI (Control)                  │  MoveHistoryPanel              │
│  - update_turn_display()           │  - add_move_entry()            │
│  - show_check_warning()            │  - clear_history()             │
│  - show_game_over()                │  - highlight_current()         │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 棋盘坐标系统

```
列(Column):  0   1   2   3   4   5   6   7   8
            ┌───┬───┬───┬───┬───┬───┬───┬───┬───┐
行(Row) 0   │ 車 │ 馬 │ 象 │ 士 │ 將 │ 士 │ 象 │ 馬 │ 車 │  黑方底线
            ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
行 1        │   │   │   │   │   │   │   │   │   │
            ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
行 2        │   │ 砲 │   │   │   │   │   │ 砲 │   │  黑方炮
            ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
行 3        │ 卒 │   │ 卒 │   │ 卒 │   │ 卒 │   │ 卒 │  黑方卒
            ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
行 4        │   │   │   │   │   │   │   │   │   │  ← 楚河
            ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
行 5        │   │   │   │   │   │   │   │   │   │  ← 汉界
            ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
行 6        │ 兵 │   │ 兵 │   │ 兵 │   │ 兵 │   │ 兵 │  红方兵
            ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
行 7        │   │ 炮 │   │   │   │   │   │ 炮 │   │  红方炮
            ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
行 8        │   │   │   │   │   │   │   │   │   │
            ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
行 9        │ 車 │ 馬 │ 相 │ 仕 │ 帥 │ 仕 │ 相 │ 馬 │ 車 │  红方底线
            └───┴───┴───┴───┴───┴───┴───┴───┴───┘
```

### 关键区域边界

| 区域 | 范围 |
|------|------|
| **红方九宫** | 行 7-9, 列 3-5 |
| **黑方九宫** | 行 0-2, 列 3-5 |
| **红方区域** | 行 5-9 (兵过河后可横移) |
| **黑方区域** | 行 0-4 (卒过河后可横移) |
| **楚河汉界** | 行 4-5 之间 |

---

## 棋子走法规则

| 棋子 | 红方 | 黑方 | 走法规则 |
|------|------|------|----------|
| 将/帅 | 帥 | 將 | 九宫内直线移动一格；不能与对方将帅直接照面 |
| 士/仕 | 仕 | 士 | 九宫内斜线移动一格 |
| 象/相 | 相 | 象 | 田字斜走两格，不能过河，被塞象眼则不能走 |
| 马 | 馬 | 馬 | 日字走法，被蹩马腿则不能走 |
| 车 | 車 | 車 | 直线任意距离移动，不能越子 |
| 炮 | 炮 | 砲 | 移动同车；吃子必须隔一个棋子跳吃 |
| 兵/卒 | 兵 | 卒 | 未过河只能前进一格；过河后可前进或横移一格 |

---

## TODO 列表

### 优先级说明
- **P0 (关键)**: 游戏可玩的必要功能
- **P1 (重要)**: 预期功能，提升体验
- **P2 (优化)**: 锦上添花
- **P3 (未来)**: 仅做设计规划，暂不实现

---

### Wave 1: 基础架构 (可并行)

- [x] **1.1** [P0] 创建 `constants.gd` - 定义枚举 (Side, PieceType)、棋盘尺寸、九宫/河界边界
- [x] **1.2** [P0] 创建 `PieceData` 资源类 - type, side, character 属性
- [x] **1.3** [P0] 创建 `BoardLogic` 类 - 10x9棋盘数组、棋子放置、基本getter方法
- [ ] **1.4** [P0] 创建 `Board` 场景 - 木纹背景、使用 `_draw()` 绘制网格线
- [ ] **1.5** [P0] 创建 `EventBus` 单例 - 核心信号定义
- [ ] **1.6** [P0] 添加中文字体资源 - 支持繁体字符 (帥仕相馬車砲兵等)

**Wave 1 交付物**: 显示空棋盘，带网格线和"楚河汉界"标签

---

### Wave 2: 棋子显示 (依赖 Wave 1)

- [ ] **2.1** [P0] 创建 `Piece` 场景 - 圆形背景 + Label显示汉字
- [ ] **2.2** [P0] 实现 `BoardLogic.setup_initial_position()` - 初始棋子布局
- [ ] **2.3** [P0] 创建棋子生成系统 `Board.gd` - 根据BoardLogic状态实例化棋子
- [ ] **2.4** [P1] 设置棋子样式 - 红/黑颜色区分、合适的尺寸
- [ ] **2.5** [P0] 创建 `main.tscn` - 整合Board + 基本UI结构

**Wave 2 交付物**: 32颗棋子显示在初始位置

---

### Wave 3: 走法验证 (可并行)

- [ ] **3.1** [P0] 实现 `MoveValidator.validate_general()` - 九宫内直线移动
- [ ] **3.2** [P0] 实现 `MoveValidator.validate_advisor()` - 九宫内斜线移动
- [ ] **3.3** [P0] 实现 `MoveValidator.validate_elephant()` - 田字走、塞象眼、不过河
- [ ] **3.4** [P0] 实现 `MoveValidator.validate_horse()` - 日字走、蹩马腿
- [ ] **3.5** [P0] 实现 `MoveValidator.validate_chariot()` - 直线移动
- [ ] **3.6** [P0] 实现 `MoveValidator.validate_cannon()` - 直线移动 + 隔子吃
- [ ] **3.7** [P0] 实现 `MoveValidator.validate_soldier()` - 前进 + 过河后横移
- [ ] **3.8** [P0] 创建 `MoveGenerator.get_valid_moves(piece, pos)` - 整合所有验证器

**Wave 3 交付物**: 所有棋子走法规则实现完成，可测试

---

### Wave 4: 交互系统 (依赖 Wave 2 & 3)

- [ ] **4.1** [P0] 实现棋子点击检测 `Piece.gd` - 使用Area2D
- [ ] **4.2** [P0] 创建 `GameManager` 单例 - 协调游戏流程
- [ ] **4.3** [P0] 实现棋子选中高亮 - 视觉反馈
- [ ] **4.4** [P0] 实现合法走法指示器 - 棋盘上显示可移动位置圆点
- [ ] **4.5** [P0] 实现走棋执行 - 点击目标位置完成移动
- [ ] **4.6** [P0] 实现回合切换 - 走棋后自动换方
- [ ] **4.7** [P0] 防止选择对方棋子 - 只能选当前方棋子

**Wave 4 交付物**: 可选择棋子、查看合法走法、执行走棋

---

### Wave 5: 将军与胜负判定 (依赖 Wave 4)

- [ ] **5.1** [P0] 实现 `CheckDetector.is_in_check(side)` - 检测是否被将军
- [ ] **5.2** [P0] 实现将帅照面规则检测 - 两将不能在同一列无遮挡
- [ ] **5.3** [P0] 过滤导致被将军的走法 `MoveGenerator.filter_check_moves()`
- [ ] **5.4** [P0] 实现 `CheckDetector.is_checkmate(side)` - 无合法走法且被将军
- [ ] **5.5** [P1] 实现 `CheckDetector.is_stalemate(side)` - 无合法走法但未被将军
- [ ] **5.6** [P1] 添加将军警告视觉反馈 - UI提示"将军！"
- [ ] **5.7** [P0] 添加游戏结束检测和显示 - 胜负对话框

**Wave 5 交付物**: 完整游戏逻辑，包含胜负判定

---

### Wave 6: UI与历史记录 (可与 Wave 5 并行)

- [ ] **6.1** [P0] 创建 `StatusPanel` - 显示当前回合 (红方/黑方)
- [ ] **6.2** [P1] 创建 `MoveHistoryPanel` - 可滚动的走棋历史列表
- [ ] **6.3** [P1] 实现中文记谱法 - 如"炮二平五"、"馬八進七"
- [ ] **6.4** [P0] 添加"新游戏"按钮功能 - 重置棋盘
- [ ] **6.5** [P1] 实现走棋历史追踪 `BoardLogic` - Array[Move]
- [ ] **6.6** [P1] 实现悔棋功能 - 恢复上一步状态
- [ ] **6.7** [P1] 添加"悔棋"按钮到UI

**Wave 6 交付物**: 完整UI，包含走棋历史和悔棋功能

---

### Wave 7: 打磨优化 (核心完成后)

- [ ] **7.1** [P1] 添加棋子移动动画 - 使用Tween
- [ ] **7.2** [P1] 添加吃子动画效果 - 粒子或缩放
- [ ] **7.3** [P1] 响应式棋盘缩放 - 适配窗口大小
- [ ] **7.4** [P2] 添加棋子悬停效果 - 鼠标悬停反馈
- [ ] **7.5** [P2] 创建游戏主题资源 - 统一视觉样式
- [ ] **7.6** [P2] 添加键盘导航支持 - 无鼠标操作
- [ ] **7.7** [P2] 高亮上一步走法 - 棋盘标记

**Wave 7 交付物**: 打磨后的精美游戏

---

### Wave 8: 未来扩展 (仅规划，暂不实现)

- [ ] **8.1** [P3] 设计AI接口 - `AIPlayer` 抽象类
- [ ] **8.2** [P3] 规划存档/读档 - 使用 `GameState` 资源
- [ ] **8.3** [P3] 设计多人联机协议结构
- [ ] **8.4** [P3] 规划音效集成点
- [ ] **8.5** [P3] 可选: 添加计时器系统钩子

---

## 开发时间线估算

```
第1周: 基础 + 显示
├── Day 1-2: Wave 1 (基础架构)
│   ├── [并行] constants.gd + PieceData资源
│   ├── [并行] BoardLogic基本结构
│   ├── [并行] Board场景与网格绘制
│   └── [并行] EventBus + 字体设置
│
├── Day 3-4: Wave 2 (棋子)
│   ├── Piece场景创建
│   ├── 初始布局 + 生成系统
│   └── main.tscn整合
│
第2周: 走法 + 交互
├── Day 5-7: Wave 3 (走法验证) - 可并行
│   ├── [Worker A] 将 + 士 + 兵
│   ├── [Worker B] 象 + 马
│   └── [Worker C] 车 + 炮
│
├── Day 8-9: Wave 4 (交互)
│   ├── 点击检测 + 选择
│   ├── 走法指示器
│   └── 走棋执行
│
第3周: 游戏逻辑 + UI
├── Day 10-11: Wave 5 (将军/胜负)
│   ├── 将军检测
│   ├── 将死/困毙
│   └── 将帅照面
│
├── Day 12-13: Wave 6 (UI) - 可与Wave 5并行
│   ├── 状态面板
│   ├── 走棋历史
│   └── 悔棋系统
│
├── Day 14: Wave 7 (打磨)
│   ├── 动画效果
│   └── 响应式设计
```

---

## 技术备注

### Godot版本
- **Godot 4.6** (Forward Plus渲染器)

### 脚本语言
- **GDScript** (非C#)

### 资源管理
- 使用自定义 `Resource` 类进行数据序列化
- 检查器友好，便于调试和修改

### 输入处理
- 使用 `Area2D` + `input_event` 信号处理棋子点击
- 支持触摸设备(未来)

---

## 参考资料

- [Godot 4 官方文档](https://docs.godotengine.org/en/stable/)
- [GDScript 风格指南](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [中国象棋规则](https://zh.wikipedia.org/wiki/%E4%B8%AD%E5%9C%8B%E8%B1%A1%E6%A3%8B)

---

## License

MIT License
