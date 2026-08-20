# ElvUI AuraContainer 預設配置

本文整理 ElvUI Retail 12.1 目前預設使用的光環容器、位置、`AddGroup`／`AddSlot` 數量，以及實際傳給 Blizzard `AuraContainer` 的 filter 與 candidate 條件。

## 基準與範圍

- ElvUI 本機分支：`main`
- ElvUI commit：`cbbe904783a642148d7c39103f8cbe7691d0ce09`
- Commit 日期：2026-08-20
- Commit 標題：`Filters: This is it`
- 遊戲版本範圍：Retail 12.1
- 設定基準：全新 profile 的 `P`／`G` 預設值，不包含舊 profile migration、使用者設定或插件包覆寫。
- 框架範圍：個別 UnitFrames、PartyFrames、RaidFrames、Tank／Assist、Nameplates。
- 不包含右上角全域 Buff／Debuff 框架；它不屬於上述 unit/nameplate 框架。

## 計數口徑

下列數量都以單一 frame instance 計算。Boss／Arena 有多張框架、Party／Raid 有多個 member、Nameplates 有多個實體時，總註冊量需再乘上實際建立的 frame 數。

### AddGroup

一般圖示容器 `Auras`、`Buffs`、`Debuffs` 與 Retail `AuraBars` 都走 `AddAuraGroup`：

1. 容器本身必須 `enable = true`。
2. 只有 `filterLists.groupN.enable = true` 的組才會進入 `UF:GroupFilters()`。
3. `E:Auras_SetContainer()` 才會對留下的每一組呼叫一次 `AddAuraGroup`。

因此「容器已啟用」不等於「已有 AddGroup」。最新預設的 Player／Target `AuraBars` 就是容器啟用，但兩套 `group1.enable` 都仍為 `false`，實際 AddGroup 是 0。

### AddSlot

`AuraWatch` 與 `AuraHighlight` 使用 `AddAuraSlot`：

- `AuraWatch`：每個啟用的監控法術建立一個 slot。
- `AuraHighlight.good`：每個啟用的自訂高亮法術建立一個 slot；目前預設清單為空。
- `AuraHighlight.bad`：固定建立一個可驅散減益 slot。

`AddGroup`／`AddSlot` 數量都不是 AuraButton 數量。Group 可管理多顆按鈕，Slot 則固定代表一個匹配位置。

ElvUI 會把 `perrow * numrows` 當成每個 group 的 `maxFrameCount`，並用 `perrow` 設定 flow layout 的單行寬度；它不是整個 container 跨所有 group 共用的總上限。多個 group 各自都可能提供按鈕並繼續換行。

## Filter 語意

ElvUI 將設定中的 filter 字串原樣傳給 `AddAuraGroup`／`AddAuraSlot`。

- `||` 不是「OR」。Blizzard 解析時會略過連續分隔符產生的空項，因此 `HELPFUL||PLAYER` 等同 `HELPFUL|PLAYER`。
- 同一字串內的有效項目是同時成立的限制。
- `!FILTER` 表示排除該條件。
- `INCLUDE_NAME_PLATE_ONLY` 與 `MAW` 不支援否定。

本文 candidate 簡寫：

- `+field`：candidate 必須為 `true`。
- `-field`：candidate 必須為 `false`。
- `BL`：`excludeSpellIDs = Blacklist`，只包含 ElvUI Blacklist 中目前 `enable = true` 的法術。

ElvUI profile 裡 candidate 值 `1` 不是數字條件。它會在 `UF:GroupFilters()` 被轉成 `false`，所以本文寫成 `-field`。

目前所有預設 AddGroup 都沒有啟用 `useAllowlist`。Whitelist 雖然存在，但不會自動合併進任何預設 group。

### 常用原生條件

- `PLAYER`：玩家、玩家寵物或玩家載具施放。
- `RAID`：有益光環要求玩家可施放；有害光環要求玩家可驅散。
- `RAID_IN_COMBAT`：暴雪標記為戰鬥中應在團框顯示；搭配 `HELPFUL|PLAYER` 可取得自身 HoT。
- `RAID_PLAYER_DISPELLABLE`：玩家團隊中有人可驅散，包括敵方可驅散的有益光環。
- `DISPELLABLE`：光環本身可被驅散，不要求目前隊伍真的有對應驅散能力。
- `IMPORTANT`：暴雪標記為重要，主要涵蓋即使不可偷取也應顯示在敵方名條的有益光環。
- `BIG_DEFENSIVE`：暴雪的大型防禦分類。
- `EXTERNAL_DEFENSIVE`：暴雪的外部防禦分類。
- `CROWD_CONTROL`：暴雪的控場分類。

### Duration 條件

Retail 的 `UF:GroupFilters()` 只會把各 group 自己的 `data.maxDuration` 寫入 `candidateFilters.maxDuration`。一般 `Buffs`／`Debuffs` 容器上的 `settings.maxDuration` 雖仍會存到 container，卻不會自動進入 AddGroup candidate。

目前只有停用中的 `AuraBars.group1` 設有 group-level `maxDuration = 300`。因此下列一般圖示 group 都沒有有效的 duration candidate。

## 共用 Filter 組

以下名稱是本文為方便對照所加，不是 ElvUI 原始變數名。

### RaidDebuffs5

Player、Party 與 Raid 預設共用這套五組減益：

1. `HARMFUL||RAID`；`BL`
2. `HARMFUL||!RAID`；`+isBossOrRoleAura`、`-isFromPlayerOrPlayerPet`；`BL`
3. `HARMFUL||!RAID`；`+isPriorityAura`、`-isBossOrRoleAura`、`-isFromPlayerOrPlayerPet`；`BL`
4. `HARMFUL||DISPELLABLE||!RAID`；`-isBossOrRoleAura`、`-isPriorityAura`；`BL`
5. `HARMFUL||!RAID||!DISPELLABLE`；`-isBossOrRoleAura`、`-isPriorityAura`、`-isFromPlayerOrPlayerPet`；`BL`

### GeneralDebuffs5

Focus、Pet 與 Tank 的設定清單共用這套五組：

1. `HARMFUL||IMPORTANT||!CROWD_CONTROL`
2. `HARMFUL||RAID_PLAYER_DISPELLABLE||!CROWD_CONTROL||!IMPORTANT`；`BL`
3. `HARMFUL||CROWD_CONTROL`
4. `HARMFUL||RAID||!CROWD_CONTROL||!IMPORTANT||!RAID_PLAYER_DISPELLABLE`；`BL`
5. `HARMFUL||!CROWD_CONTROL||!IMPORTANT||!RAID_PLAYER_DISPELLABLE||!RAID`；`+isPriorityAura`；`BL`

### TargetBuffs4

Target 使用；ENEMY_NPC Nameplate 使用前三組：

1. `HELPFUL`；`+isBossOrRoleAura`
2. `HELPFUL||!IMPORTANT`；`+isStealable`、`-isBossOrRoleAura`；`BL`
3. `HELPFUL||IMPORTANT`；`-isBossOrRoleAura`
4. `HELPFUL||!IMPORTANT`；`+isFromPlayerOrPlayerPet`、`-isBossOrRoleAura`、`-isStealable`

### NameplateDebuffs2

Target、敵方 Player／NPC Nameplate 使用；Target 與 Nameplate 會排除 CC：

1. `HARMFUL||PLAYER||INCLUDE_NAME_PLATE_ONLY||!CROWD_CONTROL`；`+nameplateShowPersonal`；`BL`
2. `HARMFUL||INCLUDE_NAME_PLATE_ONLY||!CROWD_CONTROL`；`+nameplateShowAll`、`-nameplateShowPersonal`；`BL`

Boss 使用同一組概念，但兩個 filter 都沒有 `!CROWD_CONTROL`：

1. `HARMFUL||PLAYER||INCLUDE_NAME_PLATE_ONLY`；`+nameplateShowPersonal`；`BL`
2. `HARMFUL||INCLUDE_NAME_PLATE_ONLY`；`+nameplateShowAll`、`-nameplateShowPersonal`；`BL`

### FocusBuffs6

1. `HELPFUL||!BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`；`+isBossOrRoleAura`
2. `HELPFUL||!IMPORTANT||!BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`；`+isStealable`、`-isBossOrRoleAura`；`BL`
3. `HELPFUL||IMPORTANT||!BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`；`-isBossOrRoleAura`
4. `HELPFUL||RAID||!IMPORTANT||!BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`；`-isBossOrRoleAura`、`-isStealable`；`BL`
5. `HELPFUL||BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`
6. `HELPFUL||EXTERNAL_DEFENSIVE`

### BossBuffs4

1. `HELPFUL`；`+isBossOrRoleAura`
2. `HELPFUL||!IMPORTANT`；`+isStealable`、`-isBossOrRoleAura`；`BL`
3. `HELPFUL||IMPORTANT`；`-isBossOrRoleAura`
4. `HELPFUL||RAID_IN_COMBAT||PLAYER||!IMPORTANT`；`-isBossOrRoleAura`、`-isStealable`

### ArenaBuffs5

1. `HELPFUL||BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`
2. `HELPFUL||EXTERNAL_DEFENSIVE`
3. `HELPFUL||RAID_PLAYER_DISPELLABLE||!BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`
4. `HELPFUL||!BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE||!RAID_PLAYER_DISPELLABLE`；`+isStealable`；`BL`
5. `HELPFUL||RAID||!BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE||!RAID_PLAYER_DISPELLABLE`；`-isStealable`；`BL`

### ArenaDebuffs3

1. `HARMFUL||PLAYER||INCLUDE_NAME_PLATE_ONLY||!CROWD_CONTROL`；`+nameplateShowPersonal`；`BL`
2. `HARMFUL||CROWD_CONTROL`
3. `HARMFUL||INCLUDE_NAME_PLATE_ONLY||!CROWD_CONTROL`；`+nameplateShowAll`、`-nameplateShowPersonal`；`BL`

### TankBuffs5

1. `HELPFUL||!BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`；`+isBossOrRoleAura`
2. `HELPFUL||IMPORTANT||!BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`；`-isBossOrRoleAura`
3. `HELPFUL||RAID||!IMPORTANT||!BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`；`-isBossOrRoleAura`；`BL`
4. `HELPFUL||BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`
5. `HELPFUL||EXTERNAL_DEFENSIVE`

## 個別 UnitFrames

### 預設 AddGroup 總表

表中的「off (N)」表示容器關閉，但 profile 仍預先配置 N 組 enabled filter；因容器關閉，這些組不會呼叫 AddGroup。

| 框架 | Auras | Buffs | Debuffs | AuraBars | 實際 AddGroup |
| --- | ---: | ---: | ---: | ---: | ---: |
| Player | off (0) | off (2) | on 5 | on 0 | 5 |
| Target | on 1 | on 4 | on 2 | on 0 | 7 |
| TargetTarget | off (0) | off (0) | on 0 | 無 | 0 |
| TargetTargetTarget | 框架預設關閉 | 框架預設關閉 | 框架預設關閉 | 無 | 0 |
| Focus | off (0) | off (6) | on 5 | off (0) | 5 |
| FocusTarget | 框架預設關閉 | 框架預設關閉 | 框架預設關閉 | 無 | 0 |
| Pet | off (0) | off (2) | off (5) | off (0) | 0 |
| PetTarget | 框架預設關閉 | 框架預設關閉 | 框架預設關閉 | 無 | 0 |
| Boss | off (0) | on 4 | on 2 | 無 | 6 |
| Arena | off (0) | on 5 | on 3 | 無 | 8 |

### Player

- `Debuffs`：5 個 AddGroup，使用 `RaidDebuffs5`。
- 位置：框架上方左側起點，`TOPLEFT` 錨於 Frame，向右排列、換行向上；單行寬度為 8 顆。
- `Buffs`：容器關閉；若開啟會錨於 Debuffs 上方。
- Buff 預設組：`HELPFUL||EXTERNAL_DEFENSIVE`；`HELPFUL||BIG_DEFENSIVE||PLAYER||!EXTERNAL_DEFENSIVE`。
- `AuraBars`：容器開啟並位於 Debuffs 上方、向上增長，但實際 0 AddGroup。

### Target

- `Auras`：1 個 AddGroup，`HARMFUL||CROWD_CONTROL`；`BL`。
- Auras 位置：框架右側，向右延伸；每列最多 4。
- `Buffs`：4 個 AddGroup，使用 `TargetBuffs4`。
- Buffs 位置：框架上方右側起點，向左排列、換行向上；每列 8。
- `Debuffs`：2 個 AddGroup，使用 `NameplateDebuffs2`。
- Debuffs 位置：錨於 Buffs 上方右側，向左排列、換行向上；每列 8。
- `AuraBars`：容器開啟並位於 Debuffs 上方，但實際 0 AddGroup。

### TargetTarget

- `Debuffs.enable = true`，但 `group1.enable = false`。
- Buffs、Debuffs、Auras 都沒有有效 group，實際 0 AddGroup。
- 預設位置若啟用：Buffs 在框架下方左側；Debuffs 錨於 Buffs 下方右側。

`TargetTargetTarget` 複製 TargetTarget，但整個框架預設關閉，仍為 0。

### Focus

- `Debuffs`：5 個 AddGroup，使用 `GeneralDebuffs5`。
- 位置：框架上方右側起點，向左排列、換行向上；每列 5。
- `Buffs`：容器關閉，但預設配置 `FocusBuffs6`；若啟用會顯示於框架下方左側。
- `AuraBars`：關閉。

`FocusTarget` 重新建立空的 filterLists、移除 AuraBars／AuraWatch／AuraHighlight，且整個框架預設關閉，實際為 0。

### Pet

- Buffs、Debuffs、Auras、AuraBars 全部關閉，實際 0 AddGroup。
- Buffs 預設兩組：`HELPFUL||EXTERNAL_DEFENSIVE`；`HELPFUL||RAID||!EXTERNAL_DEFENSIVE`，第二組有 `BL`。
- Debuffs 預設配置 `GeneralDebuffs5`。
- 預設位置若啟用：Buffs 在框架下方左側；Debuffs 在框架下方右側，向左排列。

`PetTarget` 重新建立空的 filterLists、移除 AuraBars／AuraWatch／AuraHighlight，且整個框架預設關閉，實際為 0。

### Boss

- `Buffs`：4 個 AddGroup，使用 `BossBuffs4`。
- `Debuffs`：2 個 AddGroup，使用不排除 CC 的 Boss 版 `NameplateDebuffs2`。
- Buffs 與 Debuffs 都位於框架左側並向左延伸。
- Buffs `yOffset = 20`，Debuffs `yOffset = -3`，所以兩列在左側上下分開。
- 每個容器每列最多 3 顆。

### Arena

- `Buffs`：5 個 AddGroup，使用 `ArenaBuffs5`。
- `Debuffs`：3 個 AddGroup，使用 `ArenaDebuffs3`。
- Buffs 與 Debuffs 都位於框架左側並向左延伸。
- Buffs `yOffset = 16`，Debuffs `yOffset = -16`，兩列在左側上下分開。
- 每個容器每列最多 3 顆。
- Arena 不建立 AuraWatch 或 AuraHighlight。

## PartyFrames

### Party member

- `Auras`：關閉，0 AddGroup。
- `Buffs`：Retail 關閉；設定中預留 2 組：
  - `HELPFUL||BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`
  - `HELPFUL||EXTERNAL_DEFENSIVE`
- `Debuffs`：開啟，5 個 AddGroup，使用 `RaidDebuffs5`。
- Debuffs 位置：Party frame 右側並向右延伸；每列最多 5。
- Buffs 若啟用會顯示在 frame 左側並向左延伸。
- `AuraWatch`：啟用，slot 數量依玩家職業，見「AuraWatch」。
- `AuraHighlight`：1 個 bad slot，覆蓋 Health，見「AuraHighlight」。

因此每個正常 Party member frame 預設為 5 AddGroup，加上「職業 AuraWatch 數量 + 1」個 AddSlot。

### Party 子框架

- `targetsGroup` 預設關閉，不建立一般 Auras／Buffs／Debuffs／AuraWatch。
- `petsGroup` 預設關閉；雖會建構 AuraWatch 物件，但其 `buffIndicator.enable = false`，所以 0 AddSlot。
- 兩種 child frame 都會建構 AuraHighlight 外殼，但 child DB 沒有 `debuffHighlight` 設定，因此不會加入 slot。

## RaidFrames

### Raid1／Raid2／Raid3

Raid1 複製 Party，Raid2 複製 Raid1，Raid3 複製 Raid2。

- `Buffs`：Retail 關閉；設定中預留 Party 的 2 組 Buff filter。
- `Debuffs`：容器明確關閉；設定中仍保留 `RaidDebuffs5`。
- `Auras`：關閉。
- 實際一般 AuraContainer：0 AddGroup。
- `AuraWatch`：啟用，slot 數量依玩家職業。
- `AuraHighlight`：1 個 bad slot。
- 位置若開啟：Buffs 在 frame 左側；Raid1 Debuffs 繼承 Party 的右側位置，Raid2／Raid3 也為右側。

因此每個正常 Raid member frame 預設為 0 AddGroup，加上「職業 AuraWatch 數量 + 1」個 AddSlot。

Retail 不啟用舊式 `RaidDebuffs` element；它不是 AddGroup 或 AddSlot。

### RaidPet

- 整個 RaidPet frame 預設關閉。
- Buffs、Debuffs filterLists 都被重設為全關閉，實際 0 AddGroup。
- `buffIndicator.enable` 從 Raid1 繼承為 `true`，但 `petSpecific = true` 會改用空的 `PET` AuraWatch 清單，因此 0 AuraWatch slot。
- 若整個框架被啟用，AuraHighlight 仍會建立 1 個 bad slot。

## Tank／Assist Frames

### Tank

- Buffs、Debuffs、Auras 容器都關閉，實際 0 AddGroup。
- Buffs 設定中預留 `TankBuffs5`。
- Debuffs 設定中預留 `GeneralDebuffs5`。
- 預設位置若啟用：Buffs 在框架上方左側；Debuffs 在上方右側並向左排列；每列最多 6。
- AuraWatch 關閉。
- AuraHighlight 建立 1 個 bad slot。

### Assist

Assist 在 Tank 加入 `TankBuffs5`／`GeneralDebuffs5` 之前就先複製 Tank。

- Assist 不會繼承 Tank 後加的 group2 至 group5。
- Assist 的 Buffs／Debuffs 只有重設後的 group1，且兩者 `enable = false`。
- Buffs、Debuffs、Auras 容器也都關閉，實際 0 AddGroup。
- AuraWatch 關閉。
- AuraHighlight 建立 1 個 bad slot。

### TankTarget／AssistTarget

- 兩種 target child frame 都不建構一般 AuraContainer、AuraWatch 或 AuraHighlight。
- TankTarget 預設啟用，AssistTarget 從 Tank 複製後也預設啟用，但光環計數仍為 0。

## Group Frame 距離顯示條件

最新 `Containers.lua` 對下列 unitframeType 增加共用 range gate：

- `party`
- `raid1`、`raid2`、`raid3`
- `raidpet`
- `tank`
- `assist`

正常狀態下必須同時 `UnitIsConnected(unit)` 且 `UnitInRange(unit)`，容器才以 alpha 1 顯示；否則用 `SetAlphaFromBoolean(..., 1, 0)` 設為 alpha 0。預覽或 unit 是 player 時固定顯示。

目前只有 `UF:Configure_Auras()` 會把 `frame.unitframeType` 複製到 AuraContainer，因此此 gate 實際套用於一般 `Auras`／`Buffs`／`Debuffs` group。AuraWatch 與 AuraHighlight 雖也會呼叫 `E:Auras_GroupUnit()`，container 本身沒有設定 `unitframeType`，所以不會進入 `E.AuraGated`，也不受這個 range gate 控制。

此 gate 只改變 container alpha，不會改變 AddGroup 的註冊數量。

以全新預設實際啟用的容器來看，主要受影響的是 Party Debuffs；Raid、Tank、Assist 的一般圖示容器預設都關閉。

## AuraWatch AddSlot

### 使用框架

- 預設開啟：Party、Raid1、Raid2、Raid3。
- 預設關閉：Player、Target、Focus、Pet、Boss、Tank、Assist。
- 不建立：TargetTarget 系列、FocusTarget、PetTarget、Arena、TankTarget、AssistTarget。
- RaidPet 雖繼承開啟狀態，但其 PET 清單為空且整個框架關閉。

### Slot filter

每個啟用項目：

- `candidateFilters.includeSpellIDs = { [spellID] = true }`
- 預設 filter：`HELPFUL|PLAYER`
- 該項 `anyUnit = true` 時改用 `HELPFUL`

目前啟用項目中只有 Priest 的 Power Word: Shield（17）設為 `anyUnit = true`。其餘啟用項目都只接受玩家、玩家寵物或玩家載具施放。

### 職業數量與位置

AuraWatch 容器完整覆蓋 `frame.Health`，每個 slot 按法術資料中的 `point` 顯示在血條內。

表中是註冊的 slot 數，不代表同時可見數；多個法術屬於不同專精，部分也刻意共用同一位置。

| 玩家職業 | 預設 AddSlot | 血條內位置分布 |
| --- | ---: | --- |
| Evoker | 10 | TOPRIGHT 3、BOTTOMRIGHT 3、TOP 2、RIGHT 1、BOTTOMLEFT 1 |
| Priest | 6 | TOPRIGHT 1、TOPLEFT 1、TOP 2、BOTTOMRIGHT 1、BOTTOMLEFT 1 |
| Druid | 5 | TOPRIGHT、TOPLEFT、BOTTOMRIGHT、BOTTOMLEFT、RIGHT 各 1 |
| Paladin | 5 | TOPRIGHT 3、TOPLEFT 1、RIGHT 1 |
| Shaman | 5 | TOPRIGHT 1、BOTTOMRIGHT 2、TOPLEFT 1、TOP 1 |
| Monk | 4 | TOP 1、TOPLEFT 2、BOTTOMLEFT 1 |
| Death Knight | 0 | 無 |
| Demon Hunter | 0 | 無 |
| Hunter | 0 | 無 |
| Mage | 0 | 無 |
| Rogue | 0 | 無 |
| Warlock | 0 | 無 |
| Warrior | 0 | 無 |

`GLOBAL` 與 `PET` 預設清單目前都是空表，不會額外增加 slot。

## AuraHighlight AddSlot

Retail AuraHighlight 會建立兩個 AuraContainer，並覆蓋 Health 的 statusbar texture：

- `good`：`HELPFUL`，按 `AuraHighlightColors` 的 spell ID 建 slot；目前預設清單為空，所以 0 AddSlot。
- `bad`：固定 1 AddSlot，filter 為 `HARMFUL|RAID`，candidate 為玩家目前可處理的 `includeDispelTypes`。

全域預設 `debuffHighlighting = FILL`，所以結果是血條填色高亮，不是額外的光環圖示。

只有 `UnitCanAssist("player", unit)` 為真時 container 才啟用。因此：

- Player、Pet、Party、Raid、Tank、Assist 等友方單位可顯示。
- Target／Focus 只有在指向可協助單位時顯示。
- Boss 通常不可協助；雖然設定流程仍註冊 1 個 bad slot，container 會被停用。

建立 AuraHighlight 的主要框架：

| 框架 | good AddSlot | bad AddSlot | 預設可見條件 |
| --- | ---: | ---: | --- |
| Player | 0 | 1 | 可協助 |
| Target | 0 | 1 | Target 可協助 |
| Focus | 0 | 1 | Focus 可協助 |
| Pet | 0 | 1 | 可協助 |
| Boss | 0 | 1 | 通常因不可協助而停用 |
| Party | 0 | 1 | 可協助 |
| Raid1／2／3 | 0 | 1 | 可協助 |
| RaidPet | 0 | 1 | 整個框架預設關閉 |
| Tank／Assist | 0 | 1 | 可協助 |

Arena 不建立 AuraHighlight。Party child frame 雖建立外殼，但因 child DB 沒有 `debuffHighlight` 而不加入 slot。

## AuraBars

Player 與 Target 的 AuraBars container 預設開啟：

- 位置：`anchorPoint = ABOVE`、`attachTo = DEBUFFS`，位於 Debuffs 上方並向上增長。
- 友方預設 group1 filter：`HELPFUL||PLAYER`，group-level `maxDuration = 300`。
- 敵方預設 group1 filter：`HARMFUL||PLAYER`，group-level `maxDuration = 300`。
- 兩個 group1 都沒有設 `enable = true`，所以實際 0 AddGroup、0 bar。

Focus 與 Pet 的 AuraBars 容器預設關閉。其他列出的 UnitFrames 不建構 AuraBars。

## Nameplates

### 共用位置

所有名稱板類型都先建立 Auras、Buffs、Debuffs 三個 container；是否啟用再由各 frame type 的 profile 決定。

- `Buffs`：`TOPLEFT` 錨於 Frame，`yOffset = 5`，位於名條上方左側，向右排列、換行向上；每列最多 5。
- `Debuffs`：`TOPRIGHT` 錨於 Frame，`yOffset = 35`，位於名條上方右側且高於 Buffs，向左排列、換行向上；每列最多 5。
- `Auras`：只用於 CC 組；`RIGHT` 錨於 Frame、`xOffset = 2`，位於名條右側並向右延伸；每列最多 2。
- Nameplates 不使用 AuraWatch 或 AuraHighlight，因此沒有 AddSlot。

### 預設 AddGroup 總表

| 名條類型 | 整個 frame type | Auras | Buffs | Debuffs | 配置 AddGroup |
| --- | --- | ---: | ---: | ---: | ---: |
| PLAYER | 預設關閉 | off 0 | on 3 | on 1 | 4；實際預設不顯示 |
| FRIENDLY_PLAYER | 開啟 | on 1 | on 3 | on 1 | 5 |
| FRIENDLY_NPC | 開啟 | off 0 | on 3 | on 1 | 4 |
| ENEMY_PLAYER | 開啟 | on 1 | on 4 | on 2 | 7 |
| ENEMY_NPC | 開啟 | on 1 | on 3 | on 2 | 6 |
| TARGET | 只提供目標指示設定 | 無 | 無 | 無 | 0 |

### PLAYER

Buffs：

1. `HELPFUL||BIG_DEFENSIVE||PLAYER||!EXTERNAL_DEFENSIVE`
2. `HELPFUL||EXTERNAL_DEFENSIVE`
3. `HELPFUL||RAID_IN_COMBAT||PLAYER||!BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`

Debuffs：

1. `HARMFUL`；`BL`

整個 PLAYER nameplate type 預設 `enable = false`，所以這 4 組只是預設配置，正常預設不會顯示。

### FRIENDLY_PLAYER

Auras：

1. `HARMFUL||CROWD_CONTROL`；`BL`

Buffs：

1. `HELPFUL||BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`
2. `HELPFUL||EXTERNAL_DEFENSIVE`
3. `HELPFUL||RAID_IN_COMBAT||PLAYER||!BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`

Debuffs：

1. `HARMFUL||RAID`；`BL`

合計 5 AddGroup。CC 顯示在名條右側，其餘 Buff／Debuff 顯示在名條上方。

### FRIENDLY_NPC

Buffs 與 FRIENDLY_PLAYER 相同三組。

Debuffs：

1. `HARMFUL||RAID`；`BL`

Auras 關閉，因此合計 4 AddGroup，全在名條上方。

### ENEMY_PLAYER

Auras：

1. `HARMFUL||CROWD_CONTROL`；`BL`

Buffs：

1. `HELPFUL||BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`
2. `HELPFUL||EXTERNAL_DEFENSIVE`
3. `HELPFUL||RAID_PLAYER_DISPELLABLE||!BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE`
4. `HELPFUL||!BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE||!RAID_PLAYER_DISPELLABLE`；`+isStealable`；`BL`

Debuffs 使用 `NameplateDebuffs2`。

合計 7 AddGroup。CC 顯示在名條右側，Buff／Debuff 顯示在名條上方。

### ENEMY_NPC

Auras：

1. `HARMFUL||CROWD_CONTROL`；`BL`

Buffs 使用 `TargetBuffs4` 的前三組：

1. `HELPFUL`；`+isBossOrRoleAura`
2. `HELPFUL||!IMPORTANT`；`+isStealable`、`-isBossOrRoleAura`；`BL`
3. `HELPFUL||IMPORTANT`；`-isBossOrRoleAura`

Debuffs 使用 `NameplateDebuffs2`。

合計 6 AddGroup。CC 顯示在名條右側，Buff／Debuff 顯示在名條上方。

## 快速總結

### 實際 AddGroup

- Player 5
- Target 7
- TargetTarget 0
- Focus 5
- Pet 0
- Boss 6
- Arena 8
- 每個 Party member 5
- 每個 Raid1／2／3 member 0
- Tank 0
- Assist 0
- FRIENDLY_PLAYER Nameplate 5
- FRIENDLY_NPC Nameplate 4
- ENEMY_PLAYER Nameplate 7
- ENEMY_NPC Nameplate 6
- PLAYER Nameplate 配置 4，但整個 frame type 預設關閉

### 實際 AddSlot

- Party／Raid1／Raid2／Raid3：每個 member frame 為職業 AuraWatch 數量，加 1 個 AuraHighlight bad slot。
- Player、Target、Focus、Pet、Boss、Tank、Assist：AuraWatch 0；有 AuraHighlight 的框架各註冊 1 個 bad slot。
- Arena、Nameplates 與一般 child target frames：0。

## 參考檔案

ElvUI：

- `ElvUI/Game/Shared/Defaults/Profile.lua`
- `ElvUI/Game/Mainline/Filters/Filters.lua`
- `ElvUI/Game/Shared/Filters/Filters.lua`
- `ElvUI/Game/Shared/Modules/Auras/Containers.lua`
- `ElvUI/Game/Shared/Modules/UnitFrames/Elements/Auras.lua`
- `ElvUI/Game/Shared/Modules/UnitFrames/Elements/AuraBars.lua`
- `ElvUI/Game/Shared/Modules/UnitFrames/Elements/AuraWatch.lua`
- `ElvUI/Game/Shared/Modules/UnitFrames/Elements/AuraHighlight.lua`
- `ElvUI/Game/Shared/Modules/Nameplates/Elements/Auras.lua`
- `ElvUI/Game/Shared/Modules/UnitFrames/Units/*.lua`
- `ElvUI/Game/Shared/Modules/UnitFrames/Groups/*.lua`

Blizzard UI：

- `AddOns/Blizzard_FrameXMLUtil/AuraUtil.lua`
