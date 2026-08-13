# ElvUI Retail AuraContainer 預設配置

- 設定基準：全新預設值
- 框架範圍：UnitFrames、Party/Raid、Tank/Assist、Nameplates、AuraBars、AuraWatch 與 AuraHighlight

### Filter

-  `HELPFUL||PLAYER` 等同 `HELPFUL|PLAYER`
- `!FILTER` 表示排除
- `INCLUDE_NAME_PLATE_ONLY` 與 `MAW` 不能用 `!` 排除

### Candidate

- `candidate = true`：包含
- `candidate = false`：除外
- `useBlocklist` = `excludeSpellIDs`
- `useAllowlist`沒有預設啟用組，`Whitelist` 與 `RaidCDs` 都預設停用
- Allow List 的 `includeSpellIDs` 是限縮 filter 清單，不是 OR

### 數量

- 容器 `enable = true` 且 Group `enable = true` 時才會 `AddAuraGroup()`。
- 每個 Group 的 `maxFrameCount` 都等於該容器的 `perrow * numrows`，不是多個 Group 共用的容器總上限
- 每個 AddGroup 會預建 10 顆 AuraButton；`maxFrameCount` 小於 10 不會減少預建數量
- AddSlot 固定代表一個匹配位置，不等於普通流式 Group

### 常用條件

- `PLAYER`：玩家控制單位施放
- `RAID`：玩家可施放的增益、玩家可驅散的減益
- `RAID_IN_COMBAT`：暴雪標記為戰鬥中應在團框顯示
- `RAID_PLAYER_DISPELLABLE`：團隊中有人可以驅散，包括敵方增益
- `DISPELLABLE`：可驅散光環，不論團隊是否能驅散
- `IMPORTANT`：暴雪標記的重要光環
- `BIG_DEFENSIVE`：暴雪的大型防禦分類
- `EXTERNAL_DEFENSIVE`：暴雪的外部防禦分類
- `CROWD_CONTROL`：暴雪的控場分類

### Player UnitFrames

`Debuffs`：預設啟用，每組 8 顆，位於左上，向右排列、向上增長。

`Buffs` 預設停用；若啟用，每組 8 顆並錨在 Debuffs 上方。

| 組別 | Filter | Candidate | Named list |
| --- | --- | --- | --- |
| Debuff 1 | `HARMFUL\|\|RAID` | — | `useBlocklist` |
| Debuff 2 | `HARMFUL\|\|!RAID` | `isBossOrRoleAura = true`<br>`isFromPlayerOrPlayerPet = false` | `useBlocklist` |
| Debuff 3 | `HARMFUL\|\|!RAID` | `isPriorityAura = true`<br>`isBossOrRoleAura = false`<br>`isFromPlayerOrPlayerPet = false` | `useBlocklist` |
| Debuff 4 | `HARMFUL\|\|DISPELLABLE\|\|!RAID` | `isBossOrRoleAura = false`<br>`isPriorityAura = false` | `useBlocklist` |
| Debuff 5 | `HARMFUL\|\|!RAID\|\|!DISPELLABLE` | `isBossOrRoleAura = false`<br>`isPriorityAura = false`<br>`isFromPlayerOrPlayerPet = false` | `useBlocklist` |
| Buff 1 | `HELPFUL\|\|EXTERNAL_DEFENSIVE` | — | — |
| Buff 2 | `HELPFUL\|\|BIG_DEFENSIVE\|\|PLAYER\|\|!EXTERNAL_DEFENSIVE` | — | — |

`Auras` 預設停用。`AuraBars` 容器預設啟用，但友方與敵方的 Group 1 都沒有啟用，因此不會建立 bar。

| 組別 | Group 預設 | Filter | Candidate | Named list | maxDuration |
| --- | --- | --- | --- | --- | ---: |
| 友方 1 | 停用 | `HELPFUL\|\|PLAYER` | — | — | 300 |
| 敵方 1 | 停用 | `HARMFUL\|\|PLAYER` | — | — | 300 |

`AuraWatch` 預設停用。`AuraHighlight` 建立 1 個 bad slot。

### Target UnitFrames

`Auras`：預設啟用，每組 4 顆，位於右側並向右排列。

`Buffs`：預設啟用，每組 8 顆，位於右上，向左排列、向上增長。

`Debuffs`：預設啟用，每組 8 顆並錨在 Buffs 上方右側，向左排列、向上增長。

| 組別 | Filter | Candidate | Named list |
| --- | --- | --- | --- |
| Aura 1 | `HARMFUL\|\|CROWD_CONTROL` | — | `useBlocklist` |
| Buff 1 | `HELPFUL` | `isBossOrRoleAura = true` | — |
| Buff 2 | `HELPFUL\|\|!IMPORTANT` | `isStealable = true`<br>`isBossOrRoleAura = false` | `useBlocklist` |
| Buff 3 | `HELPFUL\|\|IMPORTANT` | `isBossOrRoleAura = false` | — |
| Buff 4 | `HELPFUL\|\|!IMPORTANT` | `isFromPlayerOrPlayerPet = true`<br>`isBossOrRoleAura = false`<br>`isStealable = false` | — |
| Debuff 1 | `HARMFUL\|\|PLAYER\|\|INCLUDE_NAME_PLATE_ONLY\|\|!CROWD_CONTROL` | `nameplateShowPersonal = true` | `useBlocklist` |
| Debuff 2 | `HARMFUL\|\|INCLUDE_NAME_PLATE_ONLY\|\|!CROWD_CONTROL` | `nameplateShowAll = true`<br>`nameplateShowPersonal = false` | `useBlocklist` |

`AuraBars` 容器預設啟用，但 Group 預設停用。`AuraWatch` 預設停用。`AuraHighlight` 建立 1 個 bad slot，只有 Target 可協助時才啟用。

### TargetTarget

框架預設啟用。

- `Buffs`：容器與 Group 1 預設停用；若啟用，每組 7 顆，位於左下，向右排列、向上增長。
- `Debuffs`：容器預設啟用，但 Group 1 預設停用；若啟用該組，每組 5 顆並錨在 Buffs 下方右側，向左排列、向上增長。
- `Auras`：預設停用，沒有啟用 Group。
- 不建立 AuraBars、AuraWatch 或 AuraHighlight。

| 組別 | 容器預設 | Group 預設 | Filter | Candidate | Named list | 備註 |
| --- | --- | --- | --- | --- | --- | --- |
| Buff 1 | 停用 | 停用 | `HELPFUL` | — | `useBlocklist` | — |
| Debuff 1 | 啟用 | 停用 | `HARMFUL` | — | `useBlocklist` | — |

### TargetTargetTarget

從 TargetTarget 複製，但整個框架預設停用。

- `Buffs`：容器與 Group 1 預設停用；若啟用，每組 7 顆，位於左下，向右排列、向上增長。
- `Debuffs`：容器預設啟用，但 Group 1 預設停用；若啟用該組，每組 5 顆，位於框架右下，向左排列、向上增長。
- `Auras`：預設停用，沒有啟用 Group。
- 不建立 AuraBars、AuraWatch 或 AuraHighlight。

| 組別 | 容器預設 | Group 預設 | Filter | Candidate | Named list | 備註 |
| --- | --- | --- | --- | --- | --- | --- |
| Buff 1 | 停用 | 停用 | `HELPFUL` | — | `useBlocklist` | — |
| Debuff 1 | 啟用 | 停用 | `HARMFUL` | — | `useBlocklist` | `attachTo = FRAME` |

### Focus UnitFrames

`Debuffs`：預設啟用，每組 5 顆，位於右上，向左排列、向上增長。

`Buffs` 預設停用；若啟用，每組 7 顆，位於左下，向右排列、向上增長。

| 組別 | Filter | Candidate | Named list |
| --- | --- | --- | --- |
| Debuff 1 | `HARMFUL\|\|IMPORTANT\|\|!CROWD_CONTROL` | — | — |
| Debuff 2 | `HARMFUL\|\|RAID_PLAYER_DISPELLABLE\|\|!CROWD_CONTROL\|\|!IMPORTANT` | — | `useBlocklist` |
| Debuff 3 | `HARMFUL\|\|CROWD_CONTROL` | — | — |
| Debuff 4 | `HARMFUL\|\|RAID\|\|!CROWD_CONTROL\|\|!IMPORTANT\|\|!RAID_PLAYER_DISPELLABLE` | — | `useBlocklist` |
| Debuff 5 | `HARMFUL\|\|!CROWD_CONTROL\|\|!IMPORTANT\|\|!RAID_PLAYER_DISPELLABLE\|\|!RAID` | `isPriorityAura = true` | `useBlocklist` |
| Buff 1 | `HELPFUL\|\|!BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | `isBossOrRoleAura = true` | — |
| Buff 2 | `HELPFUL\|\|!IMPORTANT\|\|!BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | `isStealable = true`<br>`isBossOrRoleAura = false` | `useBlocklist` |
| Buff 3 | `HELPFUL\|\|IMPORTANT\|\|!BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | `isBossOrRoleAura = false` | — |
| Buff 4 | `HELPFUL\|\|RAID\|\|!IMPORTANT\|\|!BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | `isBossOrRoleAura = false`<br>`isStealable = false` | `useBlocklist` |
| Buff 5 | `HELPFUL\|\|BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | — | — |
| Buff 6 | `HELPFUL\|\|EXTERNAL_DEFENSIVE` | — | — |

`Auras`、`AuraBars` 與 `AuraWatch` 預設停用。`AuraHighlight` 建立 1 個 bad slot，只有 Focus 可協助時才啟用。

### FocusTarget

整個框架預設停用。

- `Buffs`：容器預設停用，繼承每組 7 顆與左下位置，向右排列、向上增長；filterList 重設為預設空組。
- `Debuffs`：容器預設停用，繼承每組 5 顆與右下位置，向左排列、向上增長；filterList 重設為預設空組。
- `Auras`：預設停用，沒有啟用 Group。
- 不建立 AuraBars、AuraWatch 或 AuraHighlight。

| 組別 | 容器預設 | Group 預設 | Filter | Candidate | Named list | 備註 |
| --- | --- | --- | --- | --- | --- | --- |
| Buff 1 | 停用 | 停用 | — | — | `useBlocklist` | 沒有有效 filter 覆寫 |
| Debuff 1 | 停用 | 停用 | `HARMFUL` | — | `useBlocklist` | — |

### Pet

`Buffs`：預設停用；若啟用，每組 7 顆，位於左下，向右排列、向上增長。

`Debuffs`：預設停用；若啟用，每組 5 顆，位於右下，向左排列、向上增長。

| 組別 | Filter | Candidate | Named list |
| --- | --- | --- | --- |
| Buff 1 | `HELPFUL\|\|EXTERNAL_DEFENSIVE` | — | — |
| Buff 2 | `HELPFUL\|\|RAID\|\|!EXTERNAL_DEFENSIVE` | — | `useBlocklist` |
| Debuff 1 | `HARMFUL\|\|IMPORTANT\|\|!CROWD_CONTROL` | — | — |
| Debuff 2 | `HARMFUL\|\|RAID_PLAYER_DISPELLABLE\|\|!CROWD_CONTROL\|\|!IMPORTANT` | — | `useBlocklist` |
| Debuff 3 | `HARMFUL\|\|CROWD_CONTROL` | — | — |
| Debuff 4 | `HARMFUL\|\|RAID\|\|!CROWD_CONTROL\|\|!IMPORTANT\|\|!RAID_PLAYER_DISPELLABLE` | — | `useBlocklist` |
| Debuff 5 | `HARMFUL\|\|!CROWD_CONTROL\|\|!IMPORTANT\|\|!RAID_PLAYER_DISPELLABLE\|\|!RAID` | `isPriorityAura = true` | `useBlocklist` |

`Auras`、`AuraBars` 與 `AuraWatch` 預設停用。`AuraHighlight` 建立 1 個 bad slot。

### PetTarget

整個框架預設停用。

- `Buffs`：容器預設停用，繼承每組 7 顆與左下位置，向右排列、向上增長；filterList 重設為預設空組。
- `Debuffs`：容器預設停用，繼承每組 5 顆與右下位置，向左排列、向上增長；filterList 重設為預設空組。
- `Auras`：預設停用，沒有啟用 Group。
- 不建立 AuraBars、AuraWatch 或 AuraHighlight。

| 組別 | 容器預設 | Group 預設 | Filter | Candidate | Named list | 備註 |
| --- | --- | --- | --- | --- | --- | --- |
| Buff 1 | 停用 | 停用 | — | — | `useBlocklist` | 沒有有效 filter 覆寫 |
| Debuff 1 | 停用 | 停用 | `HARMFUL` | — | `useBlocklist` | — |

### Boss

`Buffs`：預設啟用，每組 3 顆，位於左側並向左排列，`yOffset = 20`。

`Debuffs`：預設啟用，每組 3 顆，位於左側並向左排列，`yOffset = -3`。Boss 版不排除 Crowd Control。

| 組別 | Filter | Candidate | Named list |
| --- | --- | --- | --- |
| Buff 1 | `HELPFUL` | `isBossOrRoleAura = true` | — |
| Buff 2 | `HELPFUL\|\|!IMPORTANT` | `isStealable = true`<br>`isBossOrRoleAura = false` | `useBlocklist` |
| Buff 3 | `HELPFUL\|\|IMPORTANT` | `isBossOrRoleAura = false` | — |
| Buff 4 | `HELPFUL\|\|RAID_IN_COMBAT\|\|PLAYER\|\|!IMPORTANT` | `isBossOrRoleAura = false`<br>`isStealable = false` | — |
| Debuff 1 | `HARMFUL\|\|PLAYER\|\|INCLUDE_NAME_PLATE_ONLY` | `nameplateShowPersonal = true` | `useBlocklist` |
| Debuff 2 | `HARMFUL\|\|INCLUDE_NAME_PLATE_ONLY` | `nameplateShowAll = true`<br>`nameplateShowPersonal = false` | `useBlocklist` |

`Auras` 預設停用，沒有啟用 Group。

`AuraWatch` 預設停用。`AuraHighlight` 會建立 1 個 bad slot，但 Boss 通常不可協助，因此容器通常停用。

### Arena

`Buffs`：預設啟用，每組 3 顆，位於左側並向左排列，`yOffset = 16`。

`Debuffs`：預設啟用，每組 3 顆，位於左側並向左排列，`yOffset = -16`。

| 組別 | Filter | Candidate | Named list |
| --- | --- | --- | --- |
| Buff 1 | `HELPFUL\|\|BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | — | — |
| Buff 2 | `HELPFUL\|\|EXTERNAL_DEFENSIVE` | — | — |
| Buff 3 | `HELPFUL\|\|RAID_PLAYER_DISPELLABLE\|\|!BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | — | — |
| Buff 4 | `HELPFUL\|\|!BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE\|\|!RAID_PLAYER_DISPELLABLE` | `isStealable = true` | `useBlocklist` |
| Buff 5 | `HELPFUL\|\|RAID\|\|!BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE\|\|!RAID_PLAYER_DISPELLABLE` | `isStealable = false` | `useBlocklist` |
| Debuff 1 | `HARMFUL\|\|PLAYER\|\|INCLUDE_NAME_PLATE_ONLY\|\|!CROWD_CONTROL` | `nameplateShowPersonal = true` | `useBlocklist` |
| Debuff 2 | `HARMFUL\|\|CROWD_CONTROL` | — | — |
| Debuff 3 | `HARMFUL\|\|INCLUDE_NAME_PLATE_ONLY\|\|!CROWD_CONTROL` | `nameplateShowAll = true`<br>`nameplateShowPersonal = false` | `useBlocklist` |

`Auras` 預設停用，沒有啟用 Group。

Arena 不建立 AuraWatch 或 AuraHighlight。

### PartyFrames

`Buffs`：預設停用；若啟用，每組 8 顆，位於左側並向左排列。

`Debuffs`：預設啟用，每組 5 顆，位於右側並向右排列。

| 組別 | Filter | Candidate | Named list |
| --- | --- | --- | --- |
| Buff 1 | `HELPFUL\|\|BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | — | — |
| Buff 2 | `HELPFUL\|\|EXTERNAL_DEFENSIVE` | — | — |
| Debuff 1 | `HARMFUL\|\|RAID` | — | `useBlocklist` |
| Debuff 2 | `HARMFUL\|\|!RAID` | `isBossOrRoleAura = true`<br>`isFromPlayerOrPlayerPet = false` | `useBlocklist` |
| Debuff 3 | `HARMFUL\|\|!RAID` | `isPriorityAura = true`<br>`isBossOrRoleAura = false`<br>`isFromPlayerOrPlayerPet = false` | `useBlocklist` |
| Debuff 4 | `HARMFUL\|\|DISPELLABLE\|\|!RAID` | `isBossOrRoleAura = false`<br>`isPriorityAura = false` | `useBlocklist` |
| Debuff 5 | `HARMFUL\|\|!RAID\|\|!DISPELLABLE` | `isBossOrRoleAura = false`<br>`isPriorityAura = false`<br>`isFromPlayerOrPlayerPet = false` | `useBlocklist` |

`Auras` 預設停用，沒有啟用 Group。

`AuraWatch` 預設啟用，AddSlot 數依玩家職業。`AuraHighlight` 建立 1 個 bad slot。

### Party Target Child

- `targetsGroup` 預設停用。
- 不建立普通 Auras/Buffs/Debuffs、AuraWatch 或 AuraHighlight。

### Party Pet Child

- `petsGroup` 預設停用。
- 不建立普通 Auras/Buffs/Debuffs。
- 雖建構 AuraWatch 物件，但 `buffIndicator.enable = false`，所以 0 AddSlot。
- AuraHighlight 外殼沒有 child DB 的 `debuffHighlight`，不會加入 slot。

## RaidFrames

### Raid1

Raid1 從 Party 複製。

`Buffs`：預設停用；若啟用，每組 3 顆，位於左側並向左排列。

`Debuffs`：預設停用；若啟用，每組 3 顆，位於右側並向右排列。

| 組別 | Filter | Candidate | Named list |
| --- | --- | --- | --- |
| Buff 1 | `HELPFUL\|\|BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | — | — |
| Buff 2 | `HELPFUL\|\|EXTERNAL_DEFENSIVE` | — | — |
| Debuff 1 | `HARMFUL\|\|RAID` | — | `useBlocklist` |
| Debuff 2 | `HARMFUL\|\|!RAID` | `isBossOrRoleAura = true`<br>`isFromPlayerOrPlayerPet = false` | `useBlocklist` |
| Debuff 3 | `HARMFUL\|\|!RAID` | `isPriorityAura = true`<br>`isBossOrRoleAura = false`<br>`isFromPlayerOrPlayerPet = false` | `useBlocklist` |
| Debuff 4 | `HARMFUL\|\|DISPELLABLE\|\|!RAID` | `isBossOrRoleAura = false`<br>`isPriorityAura = false` | `useBlocklist` |
| Debuff 5 | `HARMFUL\|\|!RAID\|\|!DISPELLABLE` | `isBossOrRoleAura = false`<br>`isPriorityAura = false`<br>`isFromPlayerOrPlayerPet = false` | `useBlocklist` |

`Auras` 預設停用，沒有啟用 Group。

`AuraWatch` 預設啟用，AddSlot 數依玩家職業。`AuraHighlight` 建立 1 個 bad slot。

### Raid2

Raid2 從 Raid1 複製。

`Buffs`：預設停用；若啟用，每組 3 顆，位於左側並向左排列。

`Debuffs`：預設停用；若啟用，每組 3 顆，位於右側並向右排列。

| 組別 | Filter | Candidate | Named list |
| --- | --- | --- | --- |
| Buff 1 | `HELPFUL\|\|BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | — | — |
| Buff 2 | `HELPFUL\|\|EXTERNAL_DEFENSIVE` | — | — |
| Debuff 1 | `HARMFUL\|\|RAID` | — | `useBlocklist` |
| Debuff 2 | `HARMFUL\|\|!RAID` | `isBossOrRoleAura = true`<br>`isFromPlayerOrPlayerPet = false` | `useBlocklist` |
| Debuff 3 | `HARMFUL\|\|!RAID` | `isPriorityAura = true`<br>`isBossOrRoleAura = false`<br>`isFromPlayerOrPlayerPet = false` | `useBlocklist` |
| Debuff 4 | `HARMFUL\|\|DISPELLABLE\|\|!RAID` | `isBossOrRoleAura = false`<br>`isPriorityAura = false` | `useBlocklist` |
| Debuff 5 | `HARMFUL\|\|!RAID\|\|!DISPELLABLE` | `isBossOrRoleAura = false`<br>`isPriorityAura = false`<br>`isFromPlayerOrPlayerPet = false` | `useBlocklist` |

`Auras` 預設停用，沒有啟用 Group。

`AuraWatch` 預設啟用，AddSlot 數依玩家職業。`AuraHighlight` 建立 1 個 bad slot。

### Raid3

Raid3 從 Raid2 複製。

`Buffs`：預設停用；若啟用，每組 3 顆，位於左側並向左排列。

`Debuffs`：預設停用；若啟用，每組 3 顆，位於右側並向右排列。

| 組別 | Filter | Candidate | Named list |
| --- | --- | --- | --- |
| Buff 1 | `HELPFUL\|\|BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | — | — |
| Buff 2 | `HELPFUL\|\|EXTERNAL_DEFENSIVE` | — | — |
| Debuff 1 | `HARMFUL\|\|RAID` | — | `useBlocklist` |
| Debuff 2 | `HARMFUL\|\|!RAID` | `isBossOrRoleAura = true`<br>`isFromPlayerOrPlayerPet = false` | `useBlocklist` |
| Debuff 3 | `HARMFUL\|\|!RAID` | `isPriorityAura = true`<br>`isBossOrRoleAura = false`<br>`isFromPlayerOrPlayerPet = false` | `useBlocklist` |
| Debuff 4 | `HARMFUL\|\|DISPELLABLE\|\|!RAID` | `isBossOrRoleAura = false`<br>`isPriorityAura = false` | `useBlocklist` |
| Debuff 5 | `HARMFUL\|\|!RAID\|\|!DISPELLABLE` | `isBossOrRoleAura = false`<br>`isPriorityAura = false`<br>`isFromPlayerOrPlayerPet = false` | `useBlocklist` |

`Auras` 預設停用，沒有啟用 Group。

`AuraWatch` 預設啟用，AddSlot 數依玩家職業。`AuraHighlight` 建立 1 個 bad slot。

### RaidPet

整個 RaidPet frame 預設停用。

- `Buffs`：容器預設停用，繼承每組 3 顆與左側位置；沒有啟用 Group，filterList 重設為預設空組。
- `Debuffs`：容器預設停用，繼承每組 3 顆與右側位置；沒有啟用 Group，filterList 重設為預設空組。
- `Auras`：預設停用，沒有啟用 Group。
- `buffIndicator.enable` 雖從 Raid1 繼承為 true，`petSpecific = true` 會改用空的 `PET` AuraWatch 清單，因此是 0 AuraWatch slot。
- 若整個框架手動啟用，AuraHighlight 仍會建立 1 個 bad slot。

| 組別 | 容器預設 | Group 預設 | Filter | Candidate | Named list | 備註 |
| --- | --- | --- | --- | --- | --- | --- |
| Buff 1 | 停用 | 停用 | — | — | `useBlocklist` | 沒有有效 filter 覆寫 |
| Debuff 1 | 停用 | 停用 | `HARMFUL` | — | `useBlocklist` | — |

Retail 不啟用舊式 `RaidDebuffs` element；它不是 AddGroup 或 AddSlot。

## Tank/Assist Frames

### Tank

`Buffs`：預設停用；若啟用，每組 6 顆，位於左上，向右排列、向上增長。

`Debuffs`：預設停用；若啟用，每組 6 顆，位於右上，向左排列、向上增長。

| 組別 | Filter | Candidate | Named list |
| --- | --- | --- | --- |
| Buff 1 | `HELPFUL\|\|!BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | `isBossOrRoleAura = true` | — |
| Buff 2 | `HELPFUL\|\|IMPORTANT\|\|!BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | `isBossOrRoleAura = false` | — |
| Buff 3 | `HELPFUL\|\|RAID\|\|!IMPORTANT\|\|!BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | `isBossOrRoleAura = false` | `useBlocklist` |
| Buff 4 | `HELPFUL\|\|BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | — | — |
| Buff 5 | `HELPFUL\|\|EXTERNAL_DEFENSIVE` | — | — |
| Debuff 1 | `HARMFUL\|\|IMPORTANT\|\|!CROWD_CONTROL` | — | — |
| Debuff 2 | `HARMFUL\|\|RAID_PLAYER_DISPELLABLE\|\|!CROWD_CONTROL\|\|!IMPORTANT` | — | `useBlocklist` |
| Debuff 3 | `HARMFUL\|\|CROWD_CONTROL` | — | — |
| Debuff 4 | `HARMFUL\|\|RAID\|\|!CROWD_CONTROL\|\|!IMPORTANT\|\|!RAID_PLAYER_DISPELLABLE` | — | `useBlocklist` |
| Debuff 5 | `HARMFUL\|\|!CROWD_CONTROL\|\|!IMPORTANT\|\|!RAID_PLAYER_DISPELLABLE\|\|!RAID` | `isPriorityAura = true` | `useBlocklist` |

`Auras` 與 AuraWatch 預設停用。AuraHighlight 建立 1 個 bad slot。

### Assist

Assist 在 Tank 加入上述 Group 2 至 Group 5 之前就先複製 Tank，因此不會繼承 Tank 的完整規則。

- `Buffs`：容器與 Group 1 預設停用；若啟用，每組 6 顆，位於左上，向右排列、向上增長。
- `Debuffs`：容器與 Group 1 預設停用；若啟用，每組 6 顆，位於右上，向左排列、向上增長。
- `Auras` 與 AuraWatch 預設停用。AuraHighlight 建立 1 個 bad slot。

| 組別 | 容器預設 | Group 預設 | Filter | Candidate | Named list | 備註 |
| --- | --- | --- | --- | --- | --- | --- |
| Buff 1 | 停用 | 停用 | `HELPFUL` | — | `useBlocklist` | — |
| Debuff 1 | 停用 | 停用 | `HARMFUL` | — | `useBlocklist` | — |

### TankTarget

- Target child frame 預設啟用。
- 不建構普通 AuraContainer、AuraWatch 或 AuraHighlight。

### AssistTarget

- 從 TankTarget 複製，預設啟用。
- 不建構普通 AuraContainer、AuraWatch 或 AuraHighlight。

## AuraWatch AddSlot

AuraWatch 是團框血條內的職業增益指示，不是普通流式光環 Group。

每個啟用項目使用：

- Candidate：`includeSpellIDs = { [spellID] = true }`
- 一般 filter：`HELPFUL|PLAYER`
- 該項 `anyUnit = true` 時：`HELPFUL`

目前啟用項目中，只有 Priest 的 Power Word: Shield（17）設為 `anyUnit = true`。其他啟用項目只接受玩家、玩家寵物或玩家載具施放。

### 使用框架

- 預設啟用：Party、Raid1、Raid2、Raid3。
- 預設停用：Player、Target、Focus、Pet、Boss、Tank、Assist。
- 不建立：TargetTarget、TargetTargetTarget、FocusTarget、PetTarget、Arena、TankTarget、AssistTarget、所有 Nameplates。
- RaidPet 雖繼承啟用狀態，但 PET 清單為空且整個框架停用。

### 各職業預設 AddSlot

| 玩家職業 | AddSlot | 血條內位置分布 |
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

`GLOBAL` 與 `PET` 預設清單都是空表。

## AuraHighlight AddSlot

Retail AuraHighlight 建立 good 與 bad 兩個 AuraContainer，並覆蓋 Health 的 statusbar texture。

### Good

- Filter：`HELPFUL`
- Candidate：每個 `AuraHighlightColors` 法術各自使用 `includeSpellIDs`
- 預設 `AuraHighlightColors` 為空，所以是 0 AddSlot。

### Bad

- Filter：`HARMFUL|RAID`
- Candidate：`includeDispelTypes = 玩家目前可處理的驅散類型`
- 固定建立 1 AddSlot。

全域預設 `debuffHighlighting = FILL`，因此結果是血條填色，不是額外光環圖示。容器只在 `UnitCanAssist("player", unit)` 為 true 時啟用。

建立 AuraHighlight 的主要框架：

| 框架 | Good | Bad | 預設啟用條件 |
| --- | ---: | ---: | --- |
| Player | 0 | 1 | 可協助 |
| Target | 0 | 1 | Target 可協助 |
| Focus | 0 | 1 | Focus 可協助 |
| Pet | 0 | 1 | 可協助 |
| Boss | 0 | 1 | 通常因不可協助而停用 |
| Party | 0 | 1 | 可協助 |
| Raid1/Raid2/Raid3 | 0 | 1 | 可協助 |
| RaidPet | 0 | 1 | 整個框架預設停用 |
| Tank/Assist | 0 | 1 | 可協助 |

Arena 不建立 AuraHighlight。Party child frame 雖建構外殼，但 child DB 沒有 `debuffHighlight`，所以不加入 slot。

## Nameplates

### 預建模型

現行 Retail Nameplates 不再按畫面上實際出現的名條即時建立 AuraContainer，而是初始化時固定預建：

- 40 個 plate token。
- 每個 token 預建 PLAYER、FRIENDLY_PLAYER、FRIENDLY_NPC、ENEMY_PLAYER、ENEMY_NPC 五種類型。
- 每種類型預建 Auras、Buffs、Debuffs 三個容器。
- 合計 600 個 AuraContainer。
- 每個 token 的五種類型合計 26 個 AddGroup；40 個 token 合計 1,040 個 AddGroup。
- 每個 AddGroup 預建 10 顆 AuraButton，因此合計預建 10,400 顆 AuraButton。

框架切換類型時只會把對應類型的既有容器設為 active，不會此時才建立 Group。PLAYER 類型即使預設停用，相關容器與 Group 仍已預建。

### 共用位置

- `Buffs`：容器預設啟用，每組 5 顆，位於左上，向右排列、向上增長。
- `Debuffs`：容器預設啟用，每組 5 顆，位於右上並高於 Buffs，向左排列、向上增長。
- `Auras`：每組 2 顆，專供 Crowd Control，位於右側並向右排列。
- Nameplates 不建立 AuraWatch 或 AuraHighlight。

### PLAYER Nameplate

整個 PLAYER frame type 預設停用，但相關容器與 Group 仍會預建。

`Buffs`：容器設定為啟用。

`Debuffs`：容器設定為啟用。

`Auras`：預設停用，沒有啟用 Group。

| 組別 | Filter | Candidate | Named list |
| --- | --- | --- | --- |
| Buff 1 | `HELPFUL\|\|BIG_DEFENSIVE\|\|PLAYER\|\|!EXTERNAL_DEFENSIVE` | — | — |
| Buff 2 | `HELPFUL\|\|EXTERNAL_DEFENSIVE` | — | — |
| Buff 3 | `HELPFUL\|\|RAID_IN_COMBAT\|\|PLAYER\|\|!BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | — | — |
| Debuff 1 | `HARMFUL` | — | `useBlocklist` |

### FRIENDLY_PLAYER Nameplate

`Auras`：預設啟用。

`Buffs`：預設啟用。

`Debuffs`：預設啟用。

| 組別 | Filter | Candidate | Named list |
| --- | --- | --- | --- |
| Aura 1 | `HARMFUL\|\|CROWD_CONTROL` | — | `useBlocklist` |
| Buff 1 | `HELPFUL\|\|BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | — | — |
| Buff 2 | `HELPFUL\|\|EXTERNAL_DEFENSIVE` | — | — |
| Buff 3 | `HELPFUL\|\|RAID_IN_COMBAT\|\|PLAYER\|\|!BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | — | — |
| Debuff 1 | `HARMFUL\|\|RAID` | — | `useBlocklist` |

### FRIENDLY_NPC Nameplate

`Auras`：預設停用，沒有啟用 Group。

`Buffs`：預設啟用。

`Debuffs`：預設啟用。

| 組別 | Filter | Candidate | Named list |
| --- | --- | --- | --- |
| Buff 1 | `HELPFUL\|\|BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | — | — |
| Buff 2 | `HELPFUL\|\|EXTERNAL_DEFENSIVE` | — | — |
| Buff 3 | `HELPFUL\|\|RAID_IN_COMBAT\|\|PLAYER\|\|!BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | — | — |
| Debuff 1 | `HARMFUL\|\|RAID` | — | `useBlocklist` |

### ENEMY_PLAYER Nameplate

`Auras`：預設啟用。

`Buffs`：預設啟用。

`Debuffs`：預設啟用。

| 組別 | Filter | Candidate | Named list |
| --- | --- | --- | --- |
| Aura 1 | `HARMFUL\|\|CROWD_CONTROL` | — | `useBlocklist` |
| Buff 1 | `HELPFUL\|\|BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | — | — |
| Buff 2 | `HELPFUL\|\|EXTERNAL_DEFENSIVE` | — | — |
| Buff 3 | `HELPFUL\|\|RAID_PLAYER_DISPELLABLE\|\|!BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE` | — | — |
| Buff 4 | `HELPFUL\|\|!BIG_DEFENSIVE\|\|!EXTERNAL_DEFENSIVE\|\|!RAID_PLAYER_DISPELLABLE` | `isStealable = true` | `useBlocklist` |
| Debuff 1 | `HARMFUL\|\|PLAYER\|\|INCLUDE_NAME_PLATE_ONLY\|\|!CROWD_CONTROL` | `nameplateShowPersonal = true` | `useBlocklist` |
| Debuff 2 | `HARMFUL\|\|INCLUDE_NAME_PLATE_ONLY\|\|!CROWD_CONTROL` | `nameplateShowAll = true`<br>`nameplateShowPersonal = false` | `useBlocklist` |

### ENEMY_NPC Nameplate

`Auras`：預設啟用。

`Buffs`：預設啟用。

`Debuffs`：預設啟用。

| 組別 | Filter | Candidate | Named list |
| --- | --- | --- | --- |
| Aura 1 | `HARMFUL\|\|CROWD_CONTROL` | — | `useBlocklist` |
| Buff 1 | `HELPFUL` | `isBossOrRoleAura = true` | — |
| Buff 2 | `HELPFUL\|\|!IMPORTANT` | `isStealable = true`<br>`isBossOrRoleAura = false` | `useBlocklist` |
| Buff 3 | `HELPFUL\|\|IMPORTANT` | `isBossOrRoleAura = false` | — |
| Debuff 1 | `HARMFUL\|\|PLAYER\|\|INCLUDE_NAME_PLATE_ONLY\|\|!CROWD_CONTROL` | `nameplateShowPersonal = true` | `useBlocklist` |
| Debuff 2 | `HARMFUL\|\|INCLUDE_NAME_PLATE_ONLY\|\|!CROWD_CONTROL` | `nameplateShowAll = true`<br>`nameplateShowPersonal = false` | `useBlocklist` |

### TARGET Nameplate 設定

TARGET 只提供目標指示相關設定，不是第六套名條光環類型，不建立 Auras/Buffs/Debuffs Group。

## AddGroup 快速計數

下表的普通 UnitFrame 數量是容器目前實際啟用並完成 `AddAuraGroup()` 的數量。Nameplate 數量則是每個固定 plate token 預建的數量。

| 框架 | AddGroup |
| --- | ---: |
| Player | 5 |
| Target | 7 |
| TargetTarget | 0 |
| TargetTargetTarget | 0 |
| Focus | 5 |
| FocusTarget | 0 |
| Pet | 0 |
| PetTarget | 0 |
| 每張 Boss | 6 |
| 每張 Arena | 8 |
| 每個 Party member | 5 |
| 每個 Raid1 member | 0 |
| 每個 Raid2 member | 0 |
| 每個 Raid3 member | 0 |
| RaidPet | 0 |
| Tank | 0 |
| Assist | 0 |
| PLAYER Nameplate 類型/token | 4 |
| FRIENDLY_PLAYER Nameplate 類型/token | 5 |
| FRIENDLY_NPC Nameplate 類型/token | 4 |
| ENEMY_PLAYER Nameplate 類型/token | 7 |
| ENEMY_NPC Nameplate 類型/token | 6 |

## Named Spell List 用途與沿革

### 現行用途

- `Blacklist`：目前唯一由 Retail 預設 Group 實際啟用的 named list。`UF:GroupFilters()` 把其中啟用的 ID 轉成 `excludeSpellIDs`。
- `Whitelist`：目前沒有任何預設 Group 設定 `useAllowlist = true`。玩家只能在 GUI 手動選為 Allow List 或 Block List。
- `RaidCDs`：目前沒有任何 caller 或預設 Group 引用。玩家只能在 GUI 手動選用。
- GUI 會列出所有 named list；清單本身的 `type` 不會強制它只能當白名單或黑名單。
- `E:Auras_GetFilter()` 只收集 `spell.enable = true` 的項目。Blacklist 中停用的候選不會進入 runtime。

### 歷史分界

- 2012-07-30 `23e46dfea9`：舊光環系統加入 UseBlacklist/UseWhitelist。
- 2017 `6375444f0d`：改寫為舊版 priority chain。
- 2024-10-03 `2cf4ead8b5`：明確把預設 Whitelist 限定於適合的 Buff 路徑。
- 2026-08-07 `0fc762b3bf`：Retail AuraContainer 首次接上 allow/block list candidate。
- 2026-08-11 `aaf1b1c60c`：Retail UnitFrame 建構改走 AuraContainer；舊 CustomFilter 留在非 Retail 路徑。
- 2026-08-15：逐框架 AuraContainer Group 與 GUI 設定完成主要遷移。
- 2026-08-20 `b4f89cb668`/`cbbe904783`：Player、Party、Raid 等 Group 正式接上 Blacklist 並完成目前主要預設組合。
- 2026-08-24 `81909c9436`：新增 `RaidCDs` 八個法術；Git 歷史中從未出現其他 caller。
- 現行 Mainline 的三份清單是在 12.1 期間重新建立，不是把多年舊大型清單原封不動保留下來。

## Blacklist

Blacklist 共 68 個 ID：24 個預設啟用、44 個預設停用。下列繁中名稱取自 WoW 12.1.0.69404 的 zhTW `SpellName` DB2；`[DNT]` 測試法術在 zhTW 資料中仍為英文。

### 職業團隊增益：預設停用

| Spell ID | 繁中名稱 | 預設啟用 |
| ---: | --- | --- |
| 1126 | 野性印記 | 否 |
| 1459 | 秘法智力 | 否 |
| 21562 | 真言術：韌 | 否 |
| 369459 | 魔力之源 | 否 |
| 381732 | 青銅龍的祝福 | 否 |
| 381741 | 青銅龍的祝福 | 否 |
| 381746 | 青銅龍的祝福 | 否 |
| 381748 | 青銅龍的祝福 | 否 |
| 381749 | 青銅龍的祝福 | 否 |
| 381750 | 青銅龍的祝福 | 否 |
| 381751 | 青銅龍的祝福 | 否 |
| 381752 | 青銅龍的祝福 | 否 |
| 381753 | 青銅龍的祝福 | 否 |
| 381754 | 青銅龍的祝福 | 否 |
| 381756 | 青銅龍的祝福 | 否 |
| 381757 | 青銅龍的祝福 | 否 |
| 381758 | 青銅龍的祝福 | 否 |
| 462854 | 天怒 | 否 |
| 474754 | 共生關係 | 否 |
| 6673 | 戰鬥怒吼 | 否 |

### 職業內部資源/狀態：預設停用

| Spell ID | 繁中名稱 | 預設啟用 |
| ---: | --- | --- |
| 1217607 | 虛無惡魔化身 | 否 |
| 1225789 | 虛無惡魔化身 | 否 |
| 1227702 | 崩陷之星 | 否 |
| 124255 | 醉仙緩勁 | 否 |
| 205473 | 冰柱 | 否 |
| 260286 | 長矛之尖 | 否 |
| 344179 | 氣漩武器 | 否 |
| 405189 | 滿溢之力 | 否 |

### 盜賊毒藥：預設停用

| Spell ID | 繁中名稱 | 預設啟用 |
| ---: | --- | --- |
| 2823 | 致命毒藥 | 否 |
| 315584 | 速效毒藥 | 否 |
| 3408 | 致殘毒藥 | 否 |
| 381637 | 萎縮毒藥 | 否 |
| 381664 | 毒藥增幅 | 否 |
| 8679 | 致傷毒藥 | 否 |
| 5761 | 麻痺毒藥 | 否 |

### 薩滿武器灌注：預設停用

| Spell ID | 繁中名稱 | 預設啟用 |
| ---: | --- | --- |
| 319773 | 風怒武器 | 否 |
| 319778 | 火舌武器 | 否 |
| 382021 | 大地生命武器 | 否 |
| 382022 | 大地生命武器 | 否 |
| 457496 | 喚潮者之禦 | 否 |
| 457481 | 喚潮者之禦 | 否 |
| 462757 | 雷霆之擊結界 | 否 |
| 462742 | 雷霆之擊結界 | 否 |

### 聖騎士灌注：預設啟用

| Spell ID | 繁中名稱 | 預設啟用 |
| ---: | --- | --- |
| 433568 | 聖化儀式 | 是 |
| 433583 | 裁決儀式 | 是 |

### 天空騎術：預設啟用

| Spell ID | 繁中名稱 | 預設啟用 |
| ---: | --- | --- |
| 404464 | 飛行風格：天空騎術 | 是 |
| 404468 | 飛行風格：穩速 | 是 |
| 427490 | 共乘 | 是 |
| 447959 | 共乘 - 已啟用 | 是 |
| 447960 | 共乘 - 未啟用 | 是 |
| 377234 | 快意翱翔 | 是 |
| 418590 | 靜電能量 | 是 |

### 嗜血/英勇疲勞：預設啟用

| Spell ID | 繁中名稱 | 預設啟用 |
| ---: | --- | --- |
| 160455 | 疲倦 | 是 |
| 264689 | 疲倦 | 是 |
| 390435 | 精疲力竭 | 是 |
| 57723 | 精疲力竭 | 是 |
| 57724 | 精神亢奮 | 是 |
| 80354 | 時光位移 | 是 |
| 95809 | 瘋狂 | 是 |

### 社交/排隊狀態：預設啟用

| Spell ID | 繁中名稱 | 預設啟用 |
| ---: | --- | --- |
| 1313593 | 逃亡者 | 是 |
| 26013 | 逃亡者 | 是 |
| 71041 | 地城逃亡者 | 是 |

### 一般狀態：混合

| Spell ID | 繁中名稱 | 預設啟用 |
| ---: | --- | --- |
| 308312 | 限時試煉練習 | 是 |
| 369968 | 高速競賽 | 是 |
| 388367 | 雍亞拉的狂風 | 是 |
| 1283888 | [DNT] Aura Never Secret Test Spell | 否 |

### 地城狀態：預設啟用

| Spell ID | 繁中名稱 | 預設啟用 |
| ---: | --- | --- |
| 1254550 | 秘法活化 | 是 |
| 206151 | 挑戰者的重擔 | 是 |

## Whitelist

Whitelist 共 6 個 ID，全部在清單內啟用；但沒有預設 Group 啟用 `useAllowlist`，所以全新 profile 不會自動使用它。

| Spell ID | 繁中名稱 | 分類 |
| ---: | --- | --- |
| 160029 | 復活 | 一般；等待復活 |
| 225080 | 復生 | 一般；可使用復生 |
| 255234 | 圖騰復甦 | 一般；可接受圖騰復活 |
| 10060 | 注入能量 | 牧師 |
| 29166 | 啟動 | 德魯伊 |
| 406789 | 空間悖論 | 喚能師；施放於他人 |

## RaidCDs

RaidCDs 共 8 個 ID，全部在清單內啟用；但目前沒有 caller，也沒有任何預設 Group 引用它。

| Spell ID | 繁中名稱 | 職業 |
| ---: | --- | --- |
| 64843 | 神聖禮頌 | 牧師 |
| 81782 | 真言術：壁 | 牧師 |
| 740 | 寧靜 | 德魯伊 |
| 325174 | 靈魂連結圖騰 | 薩滿 |
| 363534 | 時光倒轉 | 喚能師 |
| 97463 | 振奮咆哮 | 戰士 |
| 31821 | 精通光環 | 聖騎士 |
| 145629 | 反魔法力場 | 死亡騎士 |

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

Blizzard/資料來源：

- `AddOns/Blizzard_FrameXMLUtil/AuraUtil.lua`
- Wago DB2 `SpellName`, build `12.1.0.69404`, locale `zhTW`
