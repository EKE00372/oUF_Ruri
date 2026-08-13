# EllesmereUI Retail AuraContainer 配置

本文整理 EllesmereUI Retail 12.1 現行各類單位框架、組隊框架、玩家光環列與名條使用的 AuraContainer，逐一列出預設 filter、candidate 條件、顯示位置，以及 `AddGroup`／`AddSlot` 的實際建立模型。

## 基準與範圍

- EllesmereUI 本機分支：`main`
- EllesmereUI commit：`f7e16a7ec5f88d76309831322118623061ca7c35`
- Commit 日期：2026-08-25
- EllesmereUI 版本：9.0.2
- 遊戲版本：Retail 12.1（TOC `120100`）
- 設定基準：全新 profile 的預設值，不包含舊 profile migration、使用者新增的追蹤法術或自訂 indicator。
- 框架範圍：個別 Unit Frames、Player Aura Bars、Party／Raid／Extra Frames 與敵方 Nameplates。
- 不把 Aura Buff Reminders、武器附魔格、施法鎖定圖示等手工建立的顯示算成 AuraContainer。

## 閱讀方式

### AuraKit

- 12.1 的新光環 consumer 都經過共用 `EllesmereUI.AuraKit`，由它建立 container shell、正規化 filter 字串、註冊 style，最後呼叫原生 `AddAuraGroup()`／`AddAuraSlot()`。
- AuraKit 會把 filter token 排序成固定字串，讓語意相同的組合共用引擎 parse filter；這不會把兩個 `AddGroup` 合併成一個 Group。
- Group 宣告採 add-only 模型。filter 組合或 candidate 內容改變時，通常新增一個變體並把舊 Group 的 `maxFrameCount` 設為 0；舊 Group 與按鈕不會釋放。
- 多數建立工作透過 AuraKit scheduler 分幀執行，降低登入時同步建立大量 AuraButton 造成的卡頓。

### Filter

- 同一 filter 字串中的條件是 AND，不是 OR。
- `!FILTER` 表示排除該條件。
- `PLAYER` 由原生 filter 判定玩家、玩家寵物或玩家載具來源。
- `RAID`、`RAID_IN_COMBAT`、`RAID_PLAYER_DISPELLABLE`、`CROWD_CONTROL`、`IMPORTANT`、`BIG_DEFENSIVE`、`EXTERNAL_DEFENSIVE`、`DISPELLABLE` 都由 Blizzard AuraContainer 在引擎端判定。
- 需要 OR 的顯示集合會拆成多個互斥 Group，例如名條的「重要或可驅散增益」。

### Candidate

- `candidateFilters` 是 filter 之後的第二層條件；同一 Group 內仍是 AND。
- 常見欄位包含 `isBossAura`、`isRoleAura`、`isPriorityAura`、`isStealable`、`isFromPlayerOrPlayerPet`、`nameplateShowPersonal`、`includeDispelTypes`、`includeSpellIDs`、`excludeSpellIDs` 與 `maxDuration`。
- `includeSpellIDs` 只會縮小該 Group 原本 filter 的候選，不能把不符合 filter 的光環以 OR 方式補入。
- Spell ID candidate 仍受 12.1 AuraContainer identity gate 限制。ElleUI 對友方／不可可靠辨識單位另有 assist gate 與恢復刷新；本文只記錄現碼傳入的條件，不把它等同於所有受限場景都能讀取法術身份。

### 數量

- Blizzard 每次 `AddGroup` 會先建立一批 10 顆 AuraButton；`maxFrameCount` 小於 10 不會縮小初始批次。
- `AddSlot` 只建立一個固定匹配位置，不會像 Group 一樣預建 10 顆。
- 每個 Group 各自擁有 `maxFrameCount`，沒有跨 Group 的 container 總上限。
- Group 設為 0 或 container 隱藏只停止顯示，不會回收已建立的 Group 與 AuraButton。
- 下文的「預建按鈕」只計算初始 10 顆批次；若某 Group 日後真的需要超過 10 顆，provider 還可再擴充。

### Secret／受限資料

- 正常 Group 的分類、排序與 spell-ID candidate 都交給原生 AuraContainer，不在 Lua 逐顆讀取 secret aura data。
- Group Frames 對需要 candidate identity 的有益顯示設有 assist／phase gate；無法可靠辨識組員時隱藏該類顯示，恢復後重新 parse。純 token 的減益 Group 可繼續運作。
- Unit Frames 與 Player Aura Bars 另處理載具、過場動畫及陣營關係變動後 candidate 降級的恢復刷新。
- 本文是配置與建立模型盤點，不代表對 EllesmereUI 全專案完成 secret-safe code review。

## 個別 Unit Frames

### 適用範圍

只有以下單位已遷移到新的 AuraContainer：

- `player`
- `target`
- `focus`
- `boss1` 至 `boss5`

`pet`、`targettarget` 與 `focustarget` 仍走舊版 oUF aura element／手工路徑，不建立本節的 AuraContainer。

### 共用建立模型

- 每個已遷移單位固定建立 Buff 與 Debuff 兩個 container shell。
- 每個 polarity 先宣告一個基準 `all` Group，再依目前內容模型宣告額外 Group。
- 非玩家框架沒有選取分類時，基準 Group 本身就是顯示 Group。
- 玩家框架使用 Player Aura Bars 的內容模型，因此預設另宣告 `pball`／`pdall`；基準 Group 停泊在 0。
- 所有單位框架的 Debuff Group 都會帶入硬編碼的嗜血疲勞與 always-hide `excludeSpellIDs`。在 identity 不可用的友方情境，這類 spell-ID 排除可能受引擎 gate 限制。
- 使用者新增分類、show／hide lane 或追蹤法術後會追加 Group 變體；下列數量是全新 profile 初始值。

### Player

預設實際宣告 4 個 AddGroup、10 個 AddSlot。

`Buffs`：預設 `showBuffs = false`，基礎座標為框架左上方，最多 4 顆；整個 container 隱藏。

1. 基準 Group
   - Filter：`HELPFUL`
   - 狀態：停泊於 0
2. `pball` Group
   - Filter：`HELPFUL`
   - Candidate：預設無；選擇 Has Duration 時加入 `maxDuration = math.huge`，黑名單／hide lane 會加入 `excludeSpellIDs`
   - 狀態：因 Buff container 預設隱藏而為 0

`Debuffs`：預設 anchor 為 `none`，最多 10 顆；整個 container 隱藏。

1. 基準 Group
   - Filter：`HARMFUL`
   - 狀態：停泊於 0
2. `pdall` Group
   - Filter：`HARMFUL`
   - Candidate：嗜血疲勞與 always-hide `excludeSpellIDs`
   - 狀態：因 Debuff anchor 為 `none` 而為 0

`Dispel Overlay`：建立獨立 container，共 10 個 AddSlot。

- Magic、Curse、Disease、Poison、Bleed 各建立兩個 Slot。
- 普通版本：`HARMFUL` 加對應 `includeDispelTypes`。
- Only Dispellable by You 版本：`HARMFUL|RAID_PLAYER_DISPELLABLE` 加對應 `includeDispelTypes`。
- 預設 `dispelOverlay = none`，container 隱藏，但 10 個 Slot 已實際建立。
- Dwarf Bleed 與 Shaman Poison Cleansing Totem 是 `RAID_PLAYER_DISPELLABLE` 無法表達的特例；現碼在 by-you 模式保留對應普通 Slot 的可見性。

### Target

預設實際宣告 2 個 AddGroup、0 個 AddSlot。

1. Buff Group
   - Filter：`HELPFUL`
   - 顯示：框架左上方，最多 4 顆
2. Debuff Group
   - Filter：`HARMFUL`
   - Candidate：硬編碼 Debuff 排除清單
   - 顯示：框架左下方，最多 20 顆

`onlyPlayerDebuffs = false`，因此預設不限制施放者。Tracked Auras 的 include／exclude 清單可追加 spell-ID Group；Target 的 include 預設允許任意施放者。

### Focus

預設實際宣告 2 個 AddGroup、0 個 AddSlot。

1. Buff Group
   - Filter：`HELPFUL`
   - 顯示：預設關閉；基礎 anchor 為左上方，最多 4 顆
2. Debuff Group
   - Filter：`HARMFUL|PLAYER`
   - Candidate：硬編碼 Debuff 排除清單
   - 顯示：框架左下方，最多 10 顆

`onlyPlayerDebuffs = true`。Tracked Auras include 與 Target 一樣使用任意施放者 Group。

### Boss1 至 Boss5

每張 Boss Frame 預設宣告 2 個 AddGroup、0 個 AddSlot；五張合計 10 個 AddGroup。

1. Buff Group
   - Filter：`HELPFUL`
   - 顯示：預設關閉，最多 4 顆
2. Debuff Group
   - Filter：`HARMFUL|PLAYER`
   - Candidate：硬編碼 Debuff 排除清單
   - 顯示：`simpleDebuffs = left`，在框架左側以框架高度匹配的圖示顯示，最多 10 顆

Boss 的 Tracked Auras include 預設 Only My Casts，因此額外 Group 使用 `HARMFUL|PLAYER`；使用者可逐法術改成 any-caster，該部分會使用另一個 `HARMFUL` include Group。

### Unit Frame 快速計數

| 單位 | AddGroup | AddSlot | 初始預建 AuraButton |
|---|---:|---:|---:|
| Player | 4 | 10 | 40 + 10 slots |
| Target | 2 | 0 | 20 |
| Focus | 2 | 0 | 20 |
| Boss1–5 | 10 | 0 | 100 |
| 合計 | 18 | 10 | 180 + 10 slots |

這是宣告成本，不代表 18 個 Group 同時可見；Player 的四組與多數 Boss Buff Group 預設都停泊或隱藏。

## Player Aura Bars

### 啟用狀態與位置

- Player Aura Bars 的 master `enabled` 預設關閉，因此全新 profile 實際建立 0 個 AuraContainer、0 個 AddGroup。
- 啟用後第一次建立會讀取 Blizzard BuffFrame／DebuffFrame 在 Edit Mode 的目前位置、圖示尺寸、間距與增長方向，作為 ElleUI mover 的初始值；之後由 PAB 自己保存與控制。
- 預設 Buff 圖示 32px、每行 11、最多 3 行、最多 32 顆。
- 預設 Debuff 圖示 32px、每行 8、最多 2 行、最多 16 顆。
- `useBlizzardBuffs = true` 時不建立預設 PAB Bars，但使用者自訂 bars 仍可運作。

### 預設 Buff Bar

啟用 PAB 且保留全新內容設定時，實際建立 1 個 AddGroup。

1. Catch-all Group
   - Filter：`HELPFUL`
   - Candidate：預設無
   - 上限：最多 32 顆
   - 互動：`cancelButtons = RightButtonUp`，保留右鍵取消可取消增益的能力

內容模型與 Player UnitFrame Buffs 共用概念：

- All Buffs：顯示 catch-all。
- Has Duration：在 catch-all 加 `maxDuration = math.huge`，排除永久增益。
- Show／Hide named filters：把已解析法術加入 include union 或 catch-all 的 `excludeSpellIDs`。
- Extra Spells：加入同一個 `includeSpellIDs` union。
- 若同時需要 broad catch-all 與額外 spell union，可增加第 2 個 `HELPFUL` Group。

### 預設 Debuff Bar

啟用 PAB 且維持 Show All 時，實際建立 1 個 AddGroup。

1. Catch-all Group
   - Filter：`HARMFUL`
   - Candidate：嗜血疲勞與 always-hide `excludeSpellIDs`
   - 上限：最多 16 顆

切換為分類模式後，可依序為 Boss、Role、Priority、CC、RAID、RAID_IN_COMBAT、可驅散、Dispel Type 與 Non-Player 建立互斥 Group；hide lane 以負 token 或 candidate complement 從後續 Group 扣除重疊。舊變體只停泊，不釋放。

### Custom Bars

- 自訂 Buff Bar 各有獨立 container；解析後的所有法術合併成一個 `HELPFUL + includeSpellIDs` Group，Show All 另加 catch-all。
- 自訂 Debuff Bar 使用與預設 Debuff 相同的分類 chain，因此 Group 數量取決於使用者選取的分類。
- 預設會建立一筆停用的 External Defensives custom bar 設定；停用狀態不建立 runtime container。
- Weapon Enchantment 格是手工建立，不是 AddGroup／AddSlot。

## Party／Raid／Extra Frames

### 共用架構

- Party、Raid 與 Extra Frames 共用 `EUI_RaidFrames_AuraContainers.lua` 的兩階段建立流程。
- Phase A 先替每張已 style 的按鈕建立 bare shells 與 5 個 Dispel AddSlot。
- Phase B 只在 secure header 真正把 unit 指派給按鈕後，才建立 Debuff Manager 與 Buff Manager 的 AddGroup。
- 標準架構預建 8 個分組 Raid header × 5 人、1 個 flat Raid header × 40 人，以及 Party header × 5 人，共 85 張已 style 按鈕。
- 因每張按鈕固定有 5 個 Dispel Slot，標準框架池會先建立 425 個 AddSlot；未啟用的替代 header 仍保留這些 Slot。
- Extra Frames 預設停用；啟用時最少建立 5 張，再按需要擴張。

### Dispel Overlay

每張已 style 按鈕固定建立 5 個 AddSlot：Magic、Curse、Disease、Poison、Bleed 各一個。

- 預設 Show All：Filter `HARMFUL`，Candidate 使用該 Slot 的 `includeDispelTypes`。
- Only Dispellable by You：對能由 token 表達的類型改用 `HARMFUL|RAID_PLAYER_DISPELLABLE`。
- 預設 overlay 模式是 `fill`，不是流式圖示列；Slot 只負責讓對應顏色的 overlay／border／icon 顯隱。
- Dwarf Bleed 與 Shaman Poison Cleansing Totem 使用和 Player overlay 相同的 token-blind 補充規則。

### Debuff Manager

Debuff Manager 永遠啟用。全新 profile 的 legacy `debuffFilter = all` 會一次遷移為 Show All。

預設每張已指派 unit 的按鈕建立 2 個 AddGroup：

1. Crowd Control
   - Filter：`HARMFUL|CROWD_CONTROL`
   - 上限：3
2. Catch-all
   - Filter：`HARMFUL|!CROWD_CONTROL`
   - Candidate：always-hide 與預設啟用的嗜血疲勞 `excludeSpellIDs`
   - 上限：3

預設位置與排列：

- Anchor：框架右下角
- Grow：向左
- 每行：5
- 換行：向上
- 圖示：18px
- 間距：1px

可選分類依序為：

1. Boss：`isBossAura = true`
2. Role：`isRoleAura = true`
3. Priority：`isPriorityAura = true`
4. Crowd Control：`CROWD_CONTROL`
5. Raid：`RAID`
6. Raid in Combat：`RAID_IN_COMBAT`
7. Dispellable by You：`RAID_PLAYER_DISPELLABLE`
8. Dispel Types：`includeDispelTypes = Magic／Curse／Disease／Poison／Bleed`
9. Non-Player：`isFromPlayerOrPlayerPet = false`

分類 chain 以 `CC > Dispel > RAID > RAID_IN_COMBAT` 的 token ownership 扣除重疊；candidate 類別則以補集條件避免和 catch-all 重複。使用者新增 tile、效果或 filter 會增加 Group／Slot；舊變體採停泊模型。

已退休的 Dispellable Debuff Location split 目前固定關閉，不建立額外 container 或 Group。

### Buff Manager 2

Buff Manager 2 啟用，舊版 simple buff grid 由 `BM_BaseActive = false` 停用；現行預設只使用自訂 indicator 系統。

目前玩家專精決定整套組員框架使用哪一組 indicator：

- 非治療專精：1 個 indicator。
- Restoration Druid、Discipline／Holy Priest、Mistweaver Monk、Restoration Shaman、Holy Paladin、Preservation Evoker 與 Augmentation Evoker：3 個 indicators。

非治療專精預設：

1. Defensives & Utility
   - 位置：中央
   - 尺寸：18px
   - Filter：`HELPFUL`
   - Candidate：Defensives、Raid CDs、Utility、Externals 四個 preset 的啟用法術 union，寫入 `includeSpellIDs`
   - 施放者：any-caster

治療／Augmentation 專精再加：

2. Core Healing Buffs
   - 位置：左上，向右增長
   - Filter：`HELPFUL|PLAYER`
   - Candidate：Core Healing Buffs preset 的啟用法術與 alt IDs
3. Lesser Healing Buffs
   - 位置：右上，向左增長
   - Filter：`HELPFUL|PLAYER`
   - Candidate：Lesser Healing Buffs preset 的啟用法術與 alt IDs

預設每個 icon indicator 使用一個可壓縮的 AddGroup；選取多個 preset 時先把法術合併成一個 `includeSpellIDs`，不是每個 preset 建一個 Group。

其他 indicator 型態的建立方式：

- Icon／單一顏色 Square：每個 indicator 通常 1 個 AddGroup。
- Mixed-color Square：為了逐法術顏色改成每法術 1 個 AddSlot。
- Bar：每法術 1 個 AddSlot。
- Health Color／Background Color／Border effect：每個效果 1 個 AddSlot，candidate 使用該 indicator 的法術 union。
- Custom Order：可把一個 Group 拆成逐法術 Group，最多依目前排序清單分段；會顯著增加預建批次。
- Anchor To：把多個 indicator 接到同一個 container 連續排列，但不減少 Group 數量。

### 預設每名成員成本

| 玩家目前專精使用的 BM bucket | Debuff AddGroup | Buff AddGroup | 合計 AddGroup | 每張固定 AddSlot | 初始 Group 按鈕 |
|---|---:|---:|---:|---:|---:|
| 非治療 | 2 | 1 | 3 | 5 | 30 |
| 治療／Augmentation | 2 | 3 | 5 | 5 | 50 |

例子：

- 5 個已指派 Party unit：非治療 bucket 為 15 個 AddGroup／150 顆初始按鈕；治療／Aug bucket 為 25 個／250 顆。
- 20 個已指派 Raid unit：非治療 bucket 為 60 個 AddGroup／600 顆；治療／Aug bucket 為 100 個／1000 顆。
- 上述 AddGroup 只按真正取得 unit 的按鈕計算；425 個標準 Dispel AddSlot 是另外的固定 style-pool 成本。

## Nameplates

### 適用範圍與位置

- Aura bundle 只掛在 ElleUI 自製的敵方／可攻擊 nameplate。
- 友方 name-only、友方原生名條與玩家 personal nameplate 不使用這三個 AuraContainer。
- 預設三列位置：Debuffs 在血條上方、Buffs 在左側、Crowd Control 在右側。
- 預設尺寸：Debuff 26px、Buff 24px、CC 24px；三類間距都是 2px。
- 預設上限：Debuff 類 Group 5、Buff 類 Group 4、CC Group 2。

### Pool 模型

- 登入先排程建立 16 個 bundle。
- 進入 party／raid instance 時預熱到 25 個 bundle。
- 畫面需要更多名條時繼續增長；pool 在同一 UI session 內不縮小。
- 每個 bundle 先準備 Debuff、Buff、CC 三個 bare shell；只有位置不是 `none` 的列才完成 container 並加入 Group。停用列仍可能保留空 shell，但不建立 10-button Group 批次；已加入的 Group 也不會因之後停用而釋放。

### Debuffs

全新 profile 的 `showAllDebuffs = false`，顯示 Blizzard 名條重要標記 `nameplateShowPersonal`，並把 Crowd Control 放在獨立列。

每個預設 bundle 實際宣告 3 個 Debuff AddGroup：

1. 固定 Show All Group
   - Filter：`HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL`
   - 上限：5
   - 狀態：預設停泊於 0；啟用 Show All Debuffs 後使用
2. Important record Group
   - Filter：`HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL`
   - Candidate：`nameplateShowPersonal = true`
   - Sort：Important
   - 上限：5
3. Blood Plague once Group
   - Filter：`HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY`
   - Candidate：`includeSpellIDs = { [55078] = true }`
   - 上限：1

`hideBloodPlagueCopies = true` 預設啟用。血魄瘟疫會從其他 Debuff Group 的 candidate 排除，只由第 3 組顯示一顆，避免同一 spell ID 的多來源副本重複佔位。

Tracked Auras：

- Debuff 與 CC 各有獨立 include／exclude 清單。
- include 預設 Only My Casts；使用者可逐法術改成 any-caster。
- Any-caster include 與 own-cast include 使用兩個不同 Group，因為 `PLAYER` 必須寫在固定 filter 字串內。
- include 法術會從其他 Group 排除，避免重複顯示。
- 把 Debuffs slot 改成 Debuffs + CC 時，該 container 會再建立／啟用 `HARMFUL|CROWD_CONTROL` 分類 Group；舊 Group 仍只停泊。

### Enemy Buffs

預設模式是 Important，但實際語意是「Important OR Dispellable」，因此拆成兩個互斥 AddGroup：

1. Dispellable Group
   - Filter：`HELPFUL|INCLUDE_NAME_PLATE_ONLY|DISPELLABLE`
   - Sort：Important
   - 上限：4
   - 外觀：使用可驅散 glow style
2. Important remainder
   - Filter：`HELPFUL|INCLUDE_NAME_PLATE_ONLY|IMPORTANT|!DISPELLABLE`
   - Sort：Important
   - 上限：4
   - 外觀：普通 style

切換到 Dispellable 模式時，第 2 組停泊於 0。`DISPELLABLE` 是光環本身可被驅散，不要求玩家目前職業一定會驅散。

啟用 dispel type color 且需要區分 Magic 與非 Magic 時，第 1 組可再拆成兩個 candidate Group；這會額外建立 10 顆初始按鈕。關閉 split 後額外 Group 只停泊。

### Crowd Control

預設實際宣告 1 個 AddGroup：

1. CC Group
   - Filter：`HARMFUL|CROWD_CONTROL`
   - Sort：Default
   - 上限：2
   - 顯示：名條右側

### 預設 Nameplate 計數

每個預設 bundle：

- Debuff：3 AddGroup
- Buff：2 AddGroup
- CC：1 AddGroup
- 合計：6 AddGroup，初始預建 60 顆 AuraButton

Pool 成本：

| Pool 高水位 | Bundle | AddGroup | 初始預建 AuraButton |
|---|---:|---:|---:|
| 登入預設 | 16 | 96 | 960 |
| 副本預熱 | 25 | 150 | 1500 |

源碼附近仍有「40 bundles × 3 containers × 10」的舊效能註釋；那不是現行預設 Group 數。上表依目前實際 declaration path 計算。

## 特殊硬編碼清單

### Debuff Always Hide

Player Unit Frame、其他 Unit Frame、Player Aura Bars 與 Group Frame Debuff Manager 共用或各自複製這組排除語意。

| Spell ID | 繁中名稱 |
|---:|---|
| 1254550 | 秘法活化 |
| 308312 | 限時試煉練習 |

### 嗜血疲勞

Group Frames 預設 `hideLustDebuff = true`；Player／Unit Frame／PAB 也把下列 ID 放入 hardcoded excludes。

| Spell ID | 繁中名稱 |
|---:|---|
| 57723 | 精疲力竭 |
| 57724 | 精神亢奮 |
| 80354 | 時光位移 |
| 95809 | 瘋狂 |
| 160455 | 疲倦 |
| 264689 | 疲倦 |
| 390435 | 精疲力竭 |

### Nameplate Show Once

| Spell ID | 繁中名稱 | 用途 |
|---:|---|---|
| 55078 | 血魄瘟疫 | 多來源副本只保留一顆；不是一般 blacklist |

### Nameplate Offensive Dispel Capability

這份清單只用來判定玩家是否具有進攻驅散能力，以決定可驅散 glow 的 Magic／non-Magic split 與外觀；Aura membership 本身仍由 `DISPELLABLE` filter 決定。

| Spell ID | 繁中名稱 | 職業／用途 |
|---:|---|---|
| 370 | 淨魔術 | 薩滿 |
| 378773 | 強效淨魔術 | 薩滿 |
| 528 | 驅散魔法 | 牧師 |
| 32375 | 群體驅魔 | 牧師 |
| 278326 | 吞噬魔法 | 惡魔獵人 |
| 19505 | 吞噬魔法 | 術士寵物 |
| 19801 | 寧神射擊 | 獵人 |
| 2908 | 安撫 | 德魯伊 |
| 30449 | 法術竊取 | 法師 |
| 115078 | 點穴 | 武僧；需搭配天賦判斷 |
| 450432 | 穴位攻擊 | 點穴的進攻驅散天賦 |

## 中央增益法術庫

### 結構與用途

- 來源是 `EllesmereUI_BuffPresets.lua`。檔首註釋仍寫 10 類，但目前 `filters` 表實際有 11 類。
- 每筆以 primary spell ID 為 key，記錄 `class`、可選的 `disabled = true` 與 `alts`。
- `disabled = true` 代表該法術在 preset 初始狀態不勾選，不代表 runtime 永遠黑名單。
- `alts` 是同一光環家族的替代 ID；編輯器只顯示 primary，建立 `includeSpellIDs` 時一併展開 alternates。
- Buff Manager 2 會把同一 indicator 指派的多個 preset 合併成一個法術 union；預設不會每個分類建立一個 Group。
- Player Aura Bars 以一次性匯入／複製方式取得相同 seed，兩邊不是持續共用同一張可變資料表。
- 下表共 283 個 primary records；繁中名稱取自 Retail `12.1.0.69404` 的 zhTW `SpellName` DB2，排列順序保持原始檔案順序。

### Defensives（個人防禦）

共 69 個主 ID；預設啟用 53、停用 16。

| 主 ID | 繁中名稱 | 職業 | 預設 | 替代 ID／名稱 |
|---:|---|---|---|---|
| 48707 | 反魔法護罩 | 死亡騎士 | 啟用 | 444741 反魔法護罩 |
| 48792 | 冰錮堅韌 | 死亡騎士 | 啟用 | - |
| 49039 | 巫妖之軀 | 死亡騎士 | 停用 | - |
| 55233 | 血族之裔 | 死亡騎士 | 啟用 | - |
| 101568 | 黑暗救贖 | 死亡騎士 | 啟用 | - |
| 442715 | 刃禦 | 惡魔獵人 | 停用 | - |
| 212800 | 殘影 | 惡魔獵人 | 啟用 | - |
| 1266616 | 惡魔靜默 | 惡魔獵人 | 停用 | 394933 惡魔靜默 |
| 427912 | 獻祭光環 | 惡魔獵人 | 停用 | 258920 獻祭光環 |
| 187827 | 惡魔化身 | 惡魔獵人 | 啟用 | - |
| 207771 | 熾炎烙印 | 惡魔獵人 | 啟用 | - |
| 209426 | 黑暗 | 惡魔獵人 | 停用 | - |
| 22812 | 樹皮術 | 德魯伊 | 啟用 | - |
| 22842 | 狂暴恢復 | 德魯伊 | 啟用 | - |
| 192081 | 鋼鐵毛皮 | 德魯伊 | 停用 | - |
| 61336 | 求生本能 | 德魯伊 | 啟用 | - |
| 393903 | 熊之活力 | 德魯伊 | 停用 | - |
| 1261872 | 野性之心 | 德魯伊 | 啟用 | - |
| 404381 | 抗拒命運 | 喚能師 | 啟用 | - |
| 363916 | 黑曜鱗片 | 喚能師 | 啟用 | - |
| 374349 | 再生烈焰 | 喚能師 | 啟用 | - |
| 186265 | 巨龜守護 | 獵人 | 啟用 | - |
| 472708 | 龜殼掩護 | 獵人 | 停用 | - |
| 264735 | 適者生存 | 獵人 | 啟用 | - |
| 342246 | 時光倒轉 | 法師 | 啟用 | - |
| 235313 | 熾炎屏障 | 法師 | 停用 | - |
| 11426 | 寒冰護體 | 法師 | 停用 | - |
| 45438 | 寒冰屏障 | 法師 | 啟用 | - |
| 414658 | 冰脈鎮體 | 法師 | 啟用 | - |
| 235450 | 稜彩屏障 | 法師 | 停用 | - |
| 449336 | 愈挫愈勇 | 法師 | 啟用 | - |
| 1309793 | 增幅折射 | 法師 | 啟用 | - |
| 122783 | 祛魔訣 | 武僧 | 啟用 | - |
| 115203 | 石形絕釀 | 武僧 | 啟用 | 120954 石形絕釀 |
| 125174 | 乾坤挪移 | 武僧 | 啟用 | - |
| 132578 | 召喚玄牛怒兆 | 武僧 | 啟用 | - |
| 322507 | 天尊絕釀 | 武僧 | 啟用 | - |
| 432180 | 風之舞 | 武僧 | 停用 | - |
| 1241059 | 星界灌注 | 武僧 | 啟用 | - |
| 498 | 聖佑術 | 聖騎士 | 啟用 | 403876 聖佑術 |
| 642 | 聖盾術 | 聖騎士 | 啟用 | - |
| 184662 | 復仇聖盾 | 聖騎士 | 停用 | - |
| 31850 | 忠誠防衛者 | 聖騎士 | 啟用 | - |
| 86659 | 遠古諸王守護者 | 聖騎士 | 啟用 | - |
| 114216 | 天使之壁 | 牧師 | 停用 | 114214 天使之壁 |
| 19236 | 絕望禱言 | 牧師 | 啟用 | - |
| 47585 | 影散 | 牧師 | 啟用 | - |
| 586 | 漸隱術 | 牧師 | 啟用 | - |
| 45242 | 意志專注 | 牧師 | 停用 | 426401 意志專注 |
| 193065 | 保護之光 | 牧師 | 啟用 | - |
| 27827 | 救贖之靈 | 牧師 | 啟用 | - |
| 31224 | 暗影披風 | 盜賊 | 啟用 | - |
| 5277 | 閃避 | 盜賊 | 啟用 | - |
| 1966 | 佯攻 | 盜賊 | 啟用 | - |
| 185311 | 赤紅藥瓶 | 盜賊 | 啟用 | - |
| 108271 | 星界轉移 | 薩滿 | 啟用 | - |
| 260881 | 幽靈狼 | 薩滿 | 啟用 | - |
| 108416 | 黑暗契約 | 術士 | 啟用 | - |
| 104773 | 心志堅定 | 術士 | 啟用 | - |
| 132413 | 暗影壁壘 | 術士 | 啟用 | - |
| 387636 | 靈魂炙燃：治療石 | 術士 | 啟用 | - |
| 389614 | 深淵行者 | 術士 | 啟用 | - |
| 118038 | 劍下亡魂 | 戰士 | 啟用 | - |
| 184364 | 狂怒恢復 | 戰士 | 啟用 | - |
| 190456 | 無視苦痛 | 戰士 | 啟用 | 1277297 無視苦痛 |
| 147833 | 阻擾 | 戰士 | 啟用 | - |
| 385391 | 法術反射 | 戰士 | 啟用 | - |
| 871 | 盾牆 | 戰士 | 啟用 | - |
| 202147 | 重新振作 | 戰士 | 停用 | - |

### Active Mitigation（主動減傷）

共 5 個主 ID；預設啟用 5、停用 0。

| 主 ID | 繁中名稱 | 職業 | 預設 | 替代 ID／名稱 |
|---:|---|---|---|---|
| 77535 | 血魄護盾 | 死亡騎士 | 啟用 | - |
| 203819 | 惡魔尖刺 | 惡魔獵人 | 啟用 | - |
| 192081 | 鋼鐵毛皮 | 德魯伊 | 啟用 | - |
| 132403 | 公正之盾 | 聖騎士 | 啟用 | - |
| 132404 | 盾牌格擋 | 戰士 | 啟用 | - |

### Raid CDs（團隊冷卻）

共 11 個主 ID；預設啟用 7、停用 4。

| 主 ID | 繁中名稱 | 職業 | 預設 | 替代 ID／名稱 |
|---:|---|---|---|---|
| 145629 | 反魔法力場 | 死亡騎士 | 啟用 | 51052 反魔法力場 |
| 209426 | 黑暗 | 惡魔獵人 | 啟用 | 196718 黑暗（來源列為 alt；實際是施法／區域控制本體，且標有 `No Aura Icon`） |
| 740 | 寧靜 | 德魯伊 | 停用 | 157982 寧靜<br>1264623 寧靜（來源列為 alt；實際由 Dryad NPC 使用，且標有 `No Aura Icon`） |
| 359816 | 夢境飛翔 | 喚能師 | 停用 | 362361 夢境飛翔 |
| 363534 | 時光倒轉 | 喚能師 | 停用 | - |
| 374227 | 輕風 | 喚能師 | 啟用 | - |
| 31821 | 精通光環 | 聖騎士 | 啟用 | 317929 精通光環 |
| 64843 | 神聖禮頌 | 牧師 | 停用 | 64844 神聖禮頌 |
| 81782 | 真言術：壁 | 牧師 | 啟用 | 62618 真言術：壁 |
| 325174 | 靈魂連結圖騰 | 薩滿 | 啟用 | 98008 靈魂連結圖騰 |
| 97463 | 振奮咆哮 | 戰士 | 啟用 | 97462 振奮咆哮 |

### Externals（外部減傷）

共 10 個主 ID；預設啟用 10、停用 0。

| 主 ID | 繁中名稱 | 職業 | 預設 | 替代 ID／名稱 |
|---:|---|---|---|---|
| 102342 | 鐵樹皮術 | 德魯伊 | 啟用 | - |
| 357170 | 時間擴張 | 喚能師 | 啟用 | - |
| 53480 | 犧牲咆哮 | 獵人 | 啟用 | - |
| 116849 | 氣繭護體 | 武僧 | 啟用 | - |
| 1022 | 保護祝福 | 聖騎士 | 啟用 | 1309794 保護祝福（來源列為 alt；實際是 Lady Liadrin 使用的 NPC 版本） |
| 6940 | 犧牲祝福 | 聖騎士 | 啟用 | - |
| 204018 | 抗咒祝福 | 聖騎士 | 啟用 | - |
| 387804 | 保護迴響 | 聖騎士 | 啟用 | - |
| 47788 | 守護聖靈 | 牧師 | 啟用 | - |
| 33206 | 痛苦鎮壓 | 牧師 | 啟用 | - |

### Core Healing Buffs（核心治療增益）

共 47 個主 ID；預設啟用 11、停用 36。

| 主 ID | 繁中名稱 | 職業 | 預設 | 替代 ID／名稱 |
|---:|---|---|---|---|
| 1278914 | 夢境嚮導 | 德魯伊 | 停用 | - |
| 33763 | 生命之花 | 德魯伊 | 啟用 | 419207 生命之花<br>1227806 生命之花 |
| 8936 | 癒合 | 德魯伊 | 停用 | 419287 癒合 |
| 774 | 回春術 | 德魯伊 | 停用 | 419204 回春術 |
| 155777 | 回春術（萌芽生長） | 德魯伊 | 停用 | - |
| 439530 | 共生之花 | 德魯伊 | 停用 | - |
| 474754 | 共生關係 | 德魯伊 | 啟用 | 474750 共生關係 |
| 48438 | 野性痊癒 | 德魯伊 | 停用 | 419344 野性痊癒 |
| 409678 | 時空庇護 | 喚能師 | 停用 | - |
| 355941 | 夢境之息 | 喚能師 | 停用 | 355936 夢境之息<br>382614 夢境之息 |
| 376788 | 夢境之息 | 喚能師 | 停用 | - |
| 363502 | 夢境飛翔 | 喚能師 | 停用 | - |
| 364343 | 回音 | 喚能師 | 啟用 | - |
| 445740 | 引燃 | 喚能師 | 停用 | - |
| 373267 | 生命守縛 | 喚能師 | 啟用 | - |
| 366155 | 逆轉 | 喚能師 | 停用 | - |
| 367364 | 逆轉 | 喚能師 | 停用 | - |
| 373862 | 時空異象 | 喚能師 | 停用 | - |
| 1291636 | 時空屏障 | 喚能師 | 停用 | - |
| 409895 | 翠綠之擁 | 喚能師 | 停用 | - |
| 450769 | 和諧守護 | 武僧 | 停用 | 450521 和諧守護<br>450711 和諧守護<br>450526 和諧守護<br>450531 和諧守護 |
| 1292922 | 聚合 | 武僧 | 停用 | - |
| 124682 | 迷霧繚繞 | 武僧 | 停用 | - |
| 467281 | 飲中作樂 | 武僧 | 停用 | 427296 飲中作樂 |
| 388513 | 迷霧滿溢 | 武僧 | 停用 | - |
| 450805 | 純淨精神 | 武僧 | 停用 | - |
| 119611 | 回生迷霧 | 武僧 | 啟用 | - |
| 115175 | 舒和之霧 | 武僧 | 停用 | 1260617 舒和之霧<br>198533 舒和之霧 |
| 156910 | 虔信信標 | 聖騎士 | 啟用 | - |
| 53563 | 聖光信標 | 聖騎士 | 啟用 | - |
| 200025 | 美德信標 | 聖騎士 | 啟用 | - |
| 1244893 | 救世信標 | 聖騎士 | 啟用 | - |
| 431381 | 曙光 | 聖騎士 | 停用 | - |
| 156322 | 永恆之火 | 聖騎士 | 停用 | 461432 永恆之火 |
| 432502 | 神聖武器 | 聖騎士 | 停用 | - |
| 469703 | 戰火淬鍊 | 聖騎士 | 停用 | - |
| 194384 | 贖罪 | 牧師 | 啟用 | - |
| 77489 | 光明迴響 | 牧師 | 停用 | - |
| 17 | 真言術：盾 | 牧師 | 停用 | 1246768 真言術：盾<br>1254306 真言術：盾<br>1300008 真言術：盾（開展視野） |
| 41635 | 癒合禱言 | 牧師 | 停用 | - |
| 139 | 恢復 | 牧師 | 停用 | - |
| 453846 | 鳴響能量 | 牧師 | 停用 | 453850 鳴響能量 |
| 1253593 | 虛無之盾 | 牧師 | 停用 | 1300009 虛無之盾（開展視野） |
| 207400 | 先祖活力 | 薩滿 | 停用 | - |
| 383648 | 大地之盾 | 薩滿 | 啟用 | 974 大地之盾 |
| 444490 | 水之泡泡 | 薩滿 | 停用 | - |
| 61295 | 激流 | 薩滿 | 停用 | - |

### Lesser Healing Buffs（次要治療增益）

共 47 個主 ID；預設啟用 26、停用 21。

| 主 ID | 繁中名稱 | 職業 | 預設 | 替代 ID／名稱 |
|---:|---|---|---|---|
| 1278914 | 夢境嚮導 | 德魯伊 | 啟用 | - |
| 33763 | 生命之花 | 德魯伊 | 停用 | 419207 生命之花<br>1227806 生命之花 |
| 8936 | 癒合 | 德魯伊 | 啟用 | 419287 癒合 |
| 774 | 回春術 | 德魯伊 | 啟用 | 419204 回春術 |
| 155777 | 回春術（萌芽生長） | 德魯伊 | 啟用 | - |
| 439530 | 共生之花 | 德魯伊 | 停用 | - |
| 474754 | 共生關係 | 德魯伊 | 停用 | 474750 共生關係 |
| 48438 | 野性痊癒 | 德魯伊 | 啟用 | 419344 野性痊癒 |
| 409678 | 時空庇護 | 喚能師 | 停用 | - |
| 355941 | 夢境之息 | 喚能師 | 啟用 | 355936 夢境之息<br>382614 夢境之息 |
| 376788 | 夢境之息 | 喚能師 | 啟用 | - |
| 363502 | 夢境飛翔 | 喚能師 | 停用 | - |
| 364343 | 回音 | 喚能師 | 停用 | - |
| 445740 | 引燃 | 喚能師 | 停用 | - |
| 373267 | 生命守縛 | 喚能師 | 啟用 | - |
| 366155 | 逆轉 | 喚能師 | 啟用 | - |
| 367364 | 逆轉 | 喚能師 | 啟用 | - |
| 373862 | 時空異象 | 喚能師 | 停用 | - |
| 1291636 | 時空屏障 | 喚能師 | 停用 | - |
| 409895 | 翠綠之擁 | 喚能師 | 啟用 | - |
| 450769 | 和諧守護 | 武僧 | 啟用 | 450521 和諧守護<br>450711 和諧守護<br>450526 和諧守護<br>450531 和諧守護 |
| 1292922 | 聚合 | 武僧 | 啟用 | - |
| 124682 | 迷霧繚繞 | 武僧 | 啟用 | - |
| 467281 | 飲中作樂 | 武僧 | 停用 | 427296 飲中作樂 |
| 388513 | 迷霧滿溢 | 武僧 | 停用 | - |
| 450805 | 純淨精神 | 武僧 | 停用 | - |
| 119611 | 回生迷霧 | 武僧 | 停用 | - |
| 115175 | 舒和之霧 | 武僧 | 啟用 | 1260617 舒和之霧<br>198533 舒和之霧 |
| 156910 | 虔信信標 | 聖騎士 | 停用 | - |
| 53563 | 聖光信標 | 聖騎士 | 停用 | - |
| 200025 | 美德信標 | 聖騎士 | 停用 | - |
| 1244893 | 救世信標 | 聖騎士 | 停用 | - |
| 431381 | 曙光 | 聖騎士 | 啟用 | - |
| 156322 | 永恆之火 | 聖騎士 | 啟用 | 461432 永恆之火 |
| 432502 | 神聖武器 | 聖騎士 | 啟用 | - |
| 469703 | 戰火淬鍊 | 聖騎士 | 啟用 | - |
| 194384 | 贖罪 | 牧師 | 停用 | - |
| 77489 | 光明迴響 | 牧師 | 啟用 | - |
| 17 | 真言術：盾 | 牧師 | 啟用 | 1246768 真言術：盾<br>1254306 真言術：盾<br>1300008 真言術：盾（開展視野） |
| 41635 | 癒合禱言 | 牧師 | 啟用 | - |
| 139 | 恢復 | 牧師 | 啟用 | - |
| 453846 | 鳴響能量 | 牧師 | 停用 | 453850 鳴響能量 |
| 1253593 | 虛無之盾 | 牧師 | 啟用 | 1300009 虛無之盾（開展視野） |
| 207400 | 先祖活力 | 薩滿 | 停用 | - |
| 383648 | 大地之盾 | 薩滿 | 停用 | 974 大地之盾 |
| 444490 | 水之泡泡 | 薩滿 | 啟用 | - |
| 61295 | 激流 | 薩滿 | 啟用 | - |

### Support（支援）

共 7 個主 ID；預設啟用 3、停用 4。

| 主 ID | 繁中名稱 | 職業 | 預設 | 替代 ID／名稱 |
|---:|---|---|---|---|
| 360827 | 極熾鱗片 | 喚能師 | 啟用 | - |
| 395152 | 黯黑力量 | 喚能師 | 啟用 | 395296 黯黑力量 |
| 410263 | 煉獄的祝福 | 喚能師 | 停用 | - |
| 410089 | 先見 | 喚能師 | 啟用 | - |
| 413984 | 流沙 | 喚能師 | 停用 | - |
| 369459 | 魔力之源 | 喚能師 | 停用 | - |
| 406732 | 空間悖論 | 喚能師 | 停用 | - |

### Offensive CDs（進攻冷卻）

共 17 個主 ID；預設啟用 17、停用 0。

| 主 ID | 繁中名稱 | 職業 | 預設 | 替代 ID／名稱 |
|---:|---|---|---|---|
| 1249658 | 辛德拉苟莎之息 | 死亡騎士 | 啟用 | 152279 辛德拉苟莎之息 |
| 42650 | 亡靈大軍 | 死亡騎士 | 啟用 | - |
| 191427 | 惡魔化身 | 惡魔獵人 | 啟用 | 187827 惡魔化身<br>321067 惡魔化身<br>321068 惡魔化身<br>162264 惡魔化身 |
| 471306 | 虛無惡魔化身 | 惡魔獵人 | 啟用 | 1217605 虛無惡魔化身<br>473671 虛無惡魔化身<br>1217607 虛無惡魔化身 |
| 194223 | 星穹連線 | 德魯伊 | 啟用 | - |
| 106951 | 狂暴 | 德魯伊 | 啟用 | - |
| 50334 | 狂暴 | 德魯伊 | 啟用 | - |
| 403631 | 亙古吐息 | 喚能師 | 啟用 | - |
| 375087 | 龍之怒 | 喚能師 | 啟用 | - |
| 186254 | 狂野怒火 | 獵人 | 啟用 | 1235388 狂野怒火<br>1285912 狂野怒火<br>19574 狂野怒火 |
| 288613 | 強擊 | 獵人 | 啟用 | - |
| 190319 | 燃灼 | 法師 | 啟用 | - |
| 365350 | 秘法奔騰 | 法師 | 啟用 | 365362 秘法奔騰 |
| 1249625 | 登峰造極 | 武僧 | 啟用 | - |
| 10060 | 注入能量 | 牧師 | 啟用 | - |
| 114050 | 卓越術 | 薩滿 | 啟用 | 114051 卓越術<br>114052 卓越術<br>1219480 卓越術 |
| 107574 | 巨像化身 | 戰士 | 啟用 | - |

### Movement（移動）

共 52 個主 ID；預設啟用 51、停用 1。

| 主 ID | 繁中名稱 | 職業 | 預設 | 替代 ID／名稱 |
|---:|---|---|---|---|
| 48265 | 死神逼近 | 死亡騎士 | 啟用 | - |
| 212552 | 闇境靈行 | 死亡騎士 | 啟用 | - |
| 444347 | 死亡戰騎 | 死亡騎士 | 啟用 | - |
| 1850 | 突進 | 德魯伊 | 啟用 | 61684 突進（來源列為 alt；實際是獵人寵物技能） |
| 106898 | 奔竄咆哮 | 德魯伊 | 啟用 | 77761 奔竄咆哮<br>77764 奔竄咆哮 |
| 252216 | 虎豹突進 | 德魯伊 | 啟用 | - |
| 5215 | 潛行 | 德魯伊 | 啟用 | - |
| 340546 | 堅定追擊 | 德魯伊 | 啟用 | - |
| 400126 | 森林漫步 | 德魯伊 | 啟用 | - |
| 186257 | 獵豹守護 | 獵人 | 啟用 | 186258 獵豹守護 |
| 118922 | 疾影術 | 獵人 | 啟用 | - |
| 5384 | 假死 | 獵人 | 啟用 | - |
| 199483 | 偽裝 | 獵人 | 啟用 | - |
| 1267208 | 把握良機 | 獵人 | 啟用 | - |
| 444754 | 滑溜拋法 | 法師 | 啟用 | - |
| 130 | 緩落術 | 法師 | 啟用 | - |
| 55342 | 鏡像 | 法師 | 啟用 | - |
| 108843 | 熾烈迅捷 | 法師 | 啟用 | - |
| 110960 | 強效隱形 | 法師 | 啟用 | - |
| 382294 | 迅捷咒術 | 法師 | 啟用 | - |
| 119085 | 真氣飛龍穿 | 武僧 | 啟用 | - |
| 443569 | 赤吉迅捷 | 武僧 | 啟用 | - |
| 101545 | 翔龍腳 | 武僧 | 停用 | 標有 `No Aura Icon`，不適用於一般 `HELPFUL` AuraContainer |
| 116841 | 猛虎出閘 | 武僧 | 啟用 | - |
| 394112 | 逃離現實 | 武僧 | 啟用 | - |
| 432180 | 風之舞 | 武僧 | 啟用 | - |
| 449609 | 身輕如燕 | 武僧 | 啟用 | - |
| 276111 | 神性戰馬 | 聖騎士 | 啟用 | 221886 神性戰馬<br>221883 神性戰馬<br>276112 神性戰馬<br>254474 神性戰馬<br>254472 神性戰馬<br>254471 神性戰馬<br>221885 神性戰馬<br>254473 神性戰馬<br>363608 神性戰馬<br>294133 神性戰馬<br>221887 神性戰馬<br>1272854 神性戰馬<br>453804 神性戰馬<br>1253874 神性戰馬<br>1253723 神性戰馬<br>1253881 神性戰馬 |
| 1044 | 自由祝福 | 聖騎士 | 啟用 | - |
| 121557 | 天使之羽 | 牧師 | 啟用 | - |
| 65081 | 身心合一 | 牧師 | 啟用 | - |
| 111759 | 漂浮術 | 牧師 | 啟用 | - |
| 2983 | 疾跑 | 盜賊 | 啟用 | - |
| 1784 | 潛行 | 盜賊 | 啟用 | - |
| 31230 | 死亡謊言 | 盜賊 | 啟用 | - |
| 36554 | 暗影閃現 | 盜賊 | 啟用 | - |
| 114018 | 隱蔽護罩 | 盜賊 | 啟用 | - |
| 192082 | 疾風突進 | 薩滿 | 啟用 | - |
| 79206 | 靈行者之賜 | 薩滿 | 啟用 | - |
| 58875 | 幽魂步伐 | 薩滿 | 啟用 | 90328 Spirit Walk（來源列為 alt；實際是獵人靈獸技能，不適用於薩滿） |
| 2645 | 鬼魂之狼 | 薩滿 | 啟用 | - |
| 111400 | 燃燒狂奔 | 術士 | 啟用 | - |
| 333889 | 惡魔支配 | 術士 | 啟用 | - |
| 387626 | 靈魂炙燃 | 術士 | 啟用 | - |
| 387633 | 靈魂炙燃：惡魔法陣 | 術士 | 啟用 | - |
| 202164 | 昂首闊步 | 戰士 | 啟用 | - |
| 1244157 | 刺耳怒吼 | 戰士 | 啟用 | - |
| 358267 | 盤旋 | 喚能師 | 啟用 | - |
| 358733 | 滑翔 | 喚能師 | 啟用 | - |
| 370889 | 雙生守護者 | 喚能師 | 啟用 | - |
| 375234 | 時間螺旋 | 喚能師 | 啟用 | 375226 時間螺旋<br>375229 時間螺旋<br>375230 時間螺旋<br>375238 時間螺旋<br>375240 時間螺旋<br>375252 時間螺旋<br>375253 時間螺旋<br>375254 時間螺旋<br>375255 時間螺旋<br>375256 時間螺旋<br>375257 時間螺旋<br>375258 時間螺旋 |
| 406732 | 空間悖論 | 喚能師 | 啟用 | - |

### Utility（功能性）

共 14 個主 ID；預設啟用 7、停用 7。

| 主 ID | 繁中名稱 | 職業 | 預設 | 替代 ID／名稱 |
|---:|---|---|---|---|
| 3714 | 冰霜之徑 | 死亡騎士 | 啟用 | - |
| 29166 | 啟動 | 德魯伊 | 啟用 | - |
| 406732 | 空間悖論 | 喚能師 | 啟用 | 406789 空間悖論 |
| 390386 | 守護巨龍之怒 | 喚能師 | 停用 | - |
| 408233 | 賦予龍隊石 | 喚能師 | 停用 | - |
| 1224810 | 主人的呼喚 | 獵人 | 啟用 | 54216 主人的呼喚<br>62305 主人的呼喚 |
| 466904 | 追獵者尖嘯 | 獵人 | 停用 | - |
| 264667 | 野性之怒 | 獵人 | 停用 | 357650 野性之怒 |
| 80353 | 時間扭曲 | 法師 | 停用 | - |
| 116841 | 猛虎出閘 | 武僧 | 啟用 | - |
| 1044 | 自由祝福 | 聖騎士 | 啟用 | 299256 自由祝福（來源列為 alt；實際是 Battle for Azeroth NPC 版本） |
| 115834 | 隱蔽護罩 | 盜賊 | 啟用 | 114018 隱蔽護罩 |
| 2825 | 嗜血術 | 薩滿 | 停用 | - |
| 32182 | 英勇氣概 | 薩滿 | 停用 | - |

### Consumables（消耗品）

共 4 個主 ID；預設啟用 4、停用 0。

| 主 ID | 繁中名稱 | 職業 | 預設 | 替代 ID／名稱 |
|---:|---|---|---|---|
| 1236998 | 猛烈捨棄藥劑 | 全職業 | 啟用 | - |
| 1236616 | 潛能聖水 | 全職業 | 啟用 | - |
| 1239479 | 吞噬夢境藥水 | 全職業 | 啟用 | - |
| 1236994 | 魯莽藥水 | 全職業 | 啟用 | - |

## 非 AuraContainer 顯示

### Aura Buff Reminders

`EllesmereUI_AuraBuffReminders.lua` 直接以 `C_UnitAuras.GetPlayerAuraBySpellID()` 檢查玩家法術，沒有呼叫 AuraKit、`AddAuraGroup` 或 `AddAuraSlot`，因此不列入前述 Group／Slot 計數。

### 其他手工顯示

- Player Aura Bars 的武器附魔格不是 AuraContainer。
- Nameplate cast lockout 的 CC 圖示不是 AuraContainer。
- 尚未遷移的 Pet、TargetTarget、FocusTarget 光環不使用這套 12.1 container declaration。

## AddGroup／AddSlot 快速總覽

| 系統 | 全新 profile 的建立模型 |
|---|---|
| Migrated Unit Frames | 固定 18 AddGroup + Player 10 AddSlot |
| Player Aura Bars | Master 預設關閉；啟用兩條預設 bar 後通常 2 AddGroup |
| Group Frames | 每張已 style 按鈕固定 5 AddSlot；每張已指派 unit 預設另有 3 或 5 AddGroup |
| Nameplates | 每 bundle 預設 6 AddGroup；登入池 16、副本預熱 25，pool 只增不減 |

最主要的高水位來源不是目前畫面顯示了幾顆光環，而是本次 UI session 曾建立多少 Group、nameplate bundle 與 secure group button。把 Group 隱藏、把上限改成 0 或降低到 10 以下，都不會回收初始批次。

## 參考檔案

EllesmereUI：

- `EllesmereUI_AuraKit.lua`
- `EllesmereUI_BuffPresets.lua`
- `EllesmereUI_AuraBuffReminders.lua`
- `EllesmereUIUnitFrames/EUI_UnitFrames_AuraContainers.lua`
- `EllesmereUIUnitFrames/EllesmereUIUnitFrames_PlayerAuraBars.lua`
- `EllesmereUIUnitFrames/EllesmereUIUnitFrames.lua`
- `EllesmereUIRaidFrames/EUI_RaidFrames_AuraContainers.lua`
- `EllesmereUIRaidFrames/EUI_RaidFrames_DebuffManager.lua`
- `EllesmereUIRaidFrames/EUI_RaidFrames_BuffManager.lua`
- `EllesmereUIRaidFrames/EUI_RaidFrames_BuffManager2.lua`
- `EllesmereUIRaidFrames/EllesmereUIRaidFrames.lua`
- `EllesmereUINameplates/EUI_Nameplates_AuraContainers.lua`
- `EllesmereUINameplates/EllesmereUINameplates.lua`

Blizzard UI：

- `Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua`
- `Blizzard_AuraContainer/Blizzard_AuraContainerShared.lua`
