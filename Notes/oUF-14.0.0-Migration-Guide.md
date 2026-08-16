# oUF 13.4.5 -> 14.0.0 遷移指南

> 適用對象：內嵌或依賴 oUF、維護 layout、自製 element 或 unit frame 模組的插件開發者。
> 版本基準：官方 oUF `13.4.5`（2026-06-10）至 `14.0.0`（2026-08-10）。
> 遊戲基準：World of Warcraft MAINLINE 12.1。
> 本文只描述 oUF 的通用契約，不假設任何特定 layout 的架構。

官方完整差異：[oUF 13.4.5...14.0.0](https://github.com/oUF-wow/oUF/compare/13.4.5...14.0.0)

## 一頁摘要

升級到 14.0.0 時，至少檢查下列項目：

1. 舊 `Auras`、`Buffs`、`Debuffs` 必須改用 `frame:CreateAuras()` 建立原生 `AuraContainer`，再用 `AddGroup()` 或 `AddSlot()` 定義顯示內容。
2. 舊光環的逐次更新 callback、Lua filter、Lua sort 與手動排版 override 已移除；光環只保留建立期 `PostCreateButton(button, options)` callback。
3. `frame.unit`、`frame.realUnit`、`frame.id` 改為 `frame.__unit`、`frame.__realUnit`、`frame.__unitIndex`。
4. `Castbar` 的主要 callback 都新增 `spellID` 或其他參數；`.Time` 改由 `DurationTextBinding` 驅動，`CustomTimeText` 已移除，延遲文字改用獨立 `.Delay`。
5. `ClassPower:PostUpdate()` 在第三個參數插入 `hasCurChanged`，後續參數全部右移一位。
6. `HealthPrediction`、`PowerPrediction` element 已移除；改用 `Health`、`Power`、`AdditionalPower` 的 prediction 子元件。
7. `Totems:PostUpdate()` 不再提供數字型 `start`／`duration`，改提供 `DurationObject`。
8. `PhaseIndicator:PostUpdate()` 移除 `isInSamePhase`，只傳入 `phaseReason`。
9. `oUF.Enum.DispelType` 已移除；`oUF.colors.dispel` 改用 `"Magic"`、`"Curse"` 等字串 key。
10. 直接讀取 element 的暫存欄位不再可靠；需要資料時使用 callback 參數、公開 calculator／binding 或 widget API。
11. Nameplate 的 Added／Target callback 不再涵蓋 widgets-only 與 game object 名條，且 oUF frame 不再保存 Blizzard `WidgetContainer`／`SoftTargetFrame` 引用。

## 改動分類

- **破壞性改動**：舊 layout 可能報錯、callback 參數錯位、element 不再啟用，或顯示行為明顯改變。
- **非破壞性改動**：公開用法基本不變，但核心為 12.1 安全模型、原生資料 binding 或穩定性而更換實作。

# 破壞性改動

## 1. Auras 完整重寫

### 1.1 新的資料模型

13.4.5 的光環由 oUF 在 Lua 內完成以下工作：

- 監聽 `UNIT_AURA`。
- 讀取並保存 `AuraData`。
- 執行 `FilterAura`、`SortAuras`。
- 建立普通 `Button`。
- 寫入圖示、層數、冷卻與驅散顏色。
- 手動排列按鈕。
- 在更新過程呼叫多個 callback。

14.0.0 改為 Blizzard 12.1 的原生物件：

- `AuraContainer`
- `AuraButton`
- 原生 aura filter、candidate filter 與 sort comparator
- 原生圖示、層數、持續時間、冷卻、驅散類型、可偷取與 pandemic binding

oUF 的職責改為：

1. 提供 `frame:CreateAuras()` 建立並登記容器。
2. 提供 `Auras:AddGroup()`／`Auras:AddSlot()` 的方便封裝。
3. 提供預設 AuraButton 子元件。
4. 在 unit frame 的有效 unit 改變時，把新 unit 傳給容器。

因此，14.0.0 的 Auras 不再是傳統的「在 `self.Auras` 放一個 Frame 就會自動啟用」element。容器必須由 `CreateAuras()` 建立；欄位名稱本身不負責註冊。

### 1.2 最小可用範例

```lua
local function CreateAuraContainer(self)
    local Auras = self:CreateAuras({
        layout = AnchorUtil.FlowLayoutAxis.Horizontal,
        layoutLimit = 240,
        initialAnchor = "TOPLEFT",
        growthX = "RIGHT",
        growthY = "DOWN",
        padding = 0,
    })

    Auras:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -4)

    -- 所有 group／slot 共用的預設值。
    Auras.size = 24
    Auras.elementSpacing = 2
    Auras.lineSpacing = 2
    Auras.showCount = true
    Auras.showDuration = true
    Auras.showDebuffBorder = true

    -- 必須在 AddGroup／AddSlot 前設定；詳見 callback 章節。
    Auras.PostCreateButton = function(element, button, options)
        button.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        if button.Cooldown then
            button.Cooldown:SetDrawEdge(false)
        end

        local Background = button:CreateTexture(nil, "BACKGROUND")
        Background:SetAllPoints()
        Background:SetColorTexture(0, 0, 0, 0.8)
        button.Background = Background
    end

    local helpfulKey = Auras:AddGroup("HELPFUL", {
        maxFrameCount = 12,
        sortMethod = AuraContainerSortMethod.ExpirationOnly,
        sortDirection = AuraContainerSortDirection.Normal,
        layout = {
            layoutIndex = 1,
        },
    })

    local harmfulKey = Auras:AddGroup("HARMFUL", {
        maxFrameCount = 12,
        showDebuffBorder = true,
        sortMethod = AuraContainerSortMethod.ExpirationOnly,
        sortDirection = AuraContainerSortDirection.Normal,
        layout = {
            layoutIndex = 2,
            forceNewLine = true,
        },
    })

    -- 保存引用與 key 供 layout 自己日後調整；不是註冊所必需。
    self.Auras = Auras
    self.helpfulAuraGroupKey = helpfulKey
    self.harmfulAuraGroupKey = harmfulKey
end
```

建議把 `layout`、`growthX`、`growthY` 與 `initialAnchor` 明確寫出，不依賴版本間可能不同的預設方向。

### 1.3 `CreateAuras(options)`

主要選項：

| 選項 | 用途 |
| --- | --- |
| `layout` | `AnchorUtil.FlowLayoutAxis.Horizontal` 或 `.Vertical` |
| `layoutLimit` | 橫向 layout 的最大寬度，或直向 layout 的最大高度 |
| `initialAnchor` | 流式排版起點，例如 `"TOPLEFT"` |
| `growthX` | `"LEFT"` 或 `"RIGHT"` |
| `growthY` | `"UP"` 或 `"DOWN"` |
| `padding` | 四邊共用 padding |
| `paddingLeft/Right/Top/Bottom` | 覆蓋指定方向 padding |
| `policy` | `AuraUtil.ProcessAura` 的分類選項；搭配 `processedAuraType` candidate filter |
| `templates` | 附加到容器的 template 字串；`CustomAuraContainerTemplate` 仍由 oUF 自動加入 |

同一個 unit frame 可以呼叫多次 `CreateAuras()`，建立多個互相獨立的容器，例如分離 Buff、Debuff、重要技能與單獨提示圖示。

### 1.4 `AddGroup(filter, options)`

`AddGroup()` 建立一個會參與容器 flow layout 的動態按鈕群組，回傳 `groupKey`。

```lua
local groupKey = Auras:AddGroup("HARMFUL", {
    maxFrameCount = 8,
    candidateFilters = {
        isFromPlayerOrPlayerPet = true,
        maxDuration = 60,
    },
    sortMethod = AuraContainerSortMethod.ExpirationOnly,
    sortDirection = AuraContainerSortDirection.Normal,
    layout = {
        elementSpacing = 2,
        lineSpacing = 2,
        groupSpacing = 4,
        groupLineSpacing = 4,
        forceNewLine = false,
        layoutIndex = 1,
    },
})
```

oUF 對 group 的預設排序是 `AuraContainerSortMethod.ExpirationOnly`；這不是 Blizzard 原生 group 的 `Default`。

14.0.0 的共用布林選項多半以 `options.value or element.value` 合併。這表示 group 可以用 `true` 開啟容器層未開的功能，卻通常不能用 `false` 關閉容器層已設為 `true` 的功能；若各 group 的 `showCount`、`showDuration`、border、mouse 或 cooldown 設定不同，應把設定留在各 group，不要先在容器層全域開啟。

保存 `groupKey` 後，可以使用原生容器方法動態調整：

```lua
Auras:SetAuraGroupFilterString(groupKey, "HELPFUL|PLAYER")
Auras:SetAuraGroupMaxFrameCount(groupKey, 10)
Auras:SetAuraGroupCandidateFilters(groupKey, candidateFilters)
Auras:SetAuraGroupSortMethod(groupKey, sortMethod, sortDirection)
Auras:SetAuraGroupLayout(groupKey, layoutOptions)
```

14.0.0 沒有提供可安全重建所有 group 的通用 layout callback；應保存 key 並修改 group 設定。

### 1.5 `AddSlot(filter, options)`

`AddSlot()` 從符合條件的候選光環中選出排序最前的一個，適合：

- 指定法術圖示。
- 重要防禦技能。
- 驅散類型提示。
- 只需要一格的優先級顯示。

```lua
local prioritySlotButton

local function PostCreateButton(element, button, options)
    if options.slotID == "MarkOfTheWild" then
        prioritySlotButton = button
        button:ClearAllPoints()
        button:SetPoint("LEFT", element, "RIGHT", 4, 0)
    end
end

local Auras = self:CreateAuras({
    growthX = "RIGHT",
    growthY = "DOWN",
})
Auras.PostCreateButton = PostCreateButton

local slotKey = Auras:AddSlot("HELPFUL", {
    slotID = "MarkOfTheWild", -- oUF callback 自用標記
    candidateFilters = {
        includeSpellIDs = {
            [1126] = true,
        },
    },
    sortMethod = AuraContainerSortMethod.Default,
    sortDirection = AuraContainerSortDirection.Normal,
})
```

slot 不參與 group 的動態 flow layout，應在建立 callback 中定位。oUF 的 `AddSlot()` 回傳 `slotKey`；若還要直接保存按鈕引用，可像上例在建立 callback 中取得。

可用原生方法修改 slot：

```lua
Auras:SetAuraSlotFilterString(slotKey, "HELPFUL")
Auras:SetAuraSlotCandidateFilters(slotKey, candidateFilters)
Auras:SetAuraSlotSortMethod(slotKey, sortMethod, sortDirection)
```

### 1.6 filter 與 candidate filter

`AddGroup()`／`AddSlot()` 的第一個參數是標準 `AuraFilter` 字串，例如：

```lua
"HELPFUL"
"HARMFUL"
"HELPFUL|PLAYER"
"HARMFUL|RAID"
```

同一字串中的條件是 AND；需要 OR 時建立多個 group 或 slot。

`candidateFilters` 會在 filter 字串之後繼續篩選，所有非 nil 條件同樣是 AND。12.1 支援：

| candidate filter | 說明 |
| --- | --- |
| `includeSpellIDs` | 只允許 map 中的 spell ID |
| `excludeSpellIDs` | 排除 map 中的 spell ID |
| `includeDispelTypes` | 只允許指定驅散類型名稱，例如 `{ Magic = true }` |
| `excludeDispelTypes` | 排除指定驅散類型名稱 |
| `maxDuration` | 允許的最大基礎持續時間；設定後永久光環不會通過 |
| `processedAuraType` | 只允許 `AuraUtil.ProcessAura` 的指定分類 |
| `isFromPlayerOrPlayerPet` | 是否來自玩家或玩家寵物 |
| `isRoleAura` | 是否為角色職責相關光環 |
| `isPriorityAura` | 是否為優先級光環 |
| `isStealable` | 是否可偷取 |
| `nameplateShowAll` | 是否帶有名條全顯示標記 |
| `nameplateShowPersonal` | 是否帶有名條個人顯示標記 |
| `canApplyAura` | 玩家是否能施放該光環 |
| `isBossAura` | 是否為 Boss 光環 |
| `isBossOrRoleAura` | 是否為 Boss 或職責光環 |

spell ID 篩選不是任意單位、任意光環皆可使用。Blizzard 只允許對「可協助單位的 helpful aura」及「不可協助單位的 harmful aura」做 spell ID matching；被標記為 `NeverSecret` 的光環例外。其他情境下 `includeSpellIDs`／`excludeSpellIDs` 檢查會被直接略過，不是把光環全部拒絕，因此白名單可能退化成顯示所有通過其餘條件的光環。不要把 spell ID filter 當成繞過受限光環資料的通用查詢。

使用 `processedAuraType` 前，必須在建立容器時啟用 processing policy：

```lua
local Auras = self:CreateAuras({
    policy = {
        ignoreBuffs = false,
        ignoreDebuffs = false,
        ignoreDispelDebuffs = false,
        displayOnlyDispellableDebuffs = false,
    },
})

Auras:AddGroup("HARMFUL", {
    candidateFilters = {
        processedAuraType = AuraUtil.AuraUpdateChangedType.Dispel,
    },
})
```

### 1.7 排序

可用排序方式：

- `AuraContainerSortMethod.Default`
- `AuraContainerSortMethod.BigDefensive`
- `AuraContainerSortMethod.UnitFrameDebuff`
- `AuraContainerSortMethod.ImportantOnly`
- `AuraContainerSortMethod.Expiration`
- `AuraContainerSortMethod.ExpirationOnly`
- `AuraContainerSortMethod.Name`
- `AuraContainerSortMethod.NameOnly`
- `AuraContainerSortMethod.AuraInstanceIDOnly`

方向使用：

- `AuraContainerSortDirection.Normal`
- `AuraContainerSortDirection.Reverse`

舊版 Lua `SortAuras`／`SortBuffs`／`SortDebuffs` 已移除。14.0.0 不應把 AuraData 拉回 Lua 再自行 `table.sort()`。

### 1.8 `PostCreateButton` 是唯一的 Auras callback

實際呼叫簽名：

```lua
local function PostCreateButton(element, button, options)
    -- element：AuraContainer
    -- button：原生 AuraButton
    -- options：建立此 group／slot 時使用的 options
end

Auras.PostCreateButton = PostCreateButton
```

使用規則：

1. **必須在 `AddGroup()`／`AddSlot()` 前指定 callback。** 原生容器在加入 group 時會立即預先建立一批按鈕。
2. callback 只代表「AuraButton 被建立」，不代表光環新增、更新或移除。
3. Blizzard 會分批預建按鈕以隱藏實際光環數量；callback 呼叫次數不能用來推算目前光環數量。
4. callback 執行時按鈕通常尚未綁定光環；不要嘗試讀取 AuraData。
5. callback 適合建立固定子元件、字體、材質、邊框與原生 binding。
6. callback 不應註冊自己的 `UNIT_AURA`、逐幀掃描 AuraButton，或用 `OnSizeChanged` 推算數量。
7. 容器停用或 element 被 pause 時，現有 aura／武器附魔 assignment 會被清除；按鈕物件仍可在之後重用，這不會把 `PostCreateButton` 變成停用／恢復通知。

14.0.0 原始碼註釋標題仍寫成 `PostCreateButton(button)`，但實際呼叫與參數說明均為 `(button, options)`；以實際呼叫為準。

### 1.9 使用原生 AuraButton 顯示能力

oUF 預設 `CreateButton` 已依選項建立並綁定下列子元件：

| oUF 選項 | 建立的欄位 | 原生方法 |
| --- | --- | --- |
| 永遠建立 | `button.Icon` | `button:SetIcon(texture)` |
| 未設定 `disableCooldown` | `button.Cooldown` | `button:SetDurationCooldown(cooldown)` |
| `showCount` | `button.Count` | `button:SetApplicationCount(fontString, options)` |
| `showDuration` | `button.Time` | `button:SetDurationText(fontString, options)` |
| `showBuffBorder`／`showDebuffBorder` | `button.Border` | `button:AddDispelTypeTexture(texture, options)` |
| `showBuffIndicator`／`showDebuffIndicator` | `button.DispelIndicator` | `button:AddDispelTypeTexture(texture, options)` |
| `showStealableBorder` | `button.Stealable` | `button:AddDispelTypeTexture(texture, options)` |

`AddDispelTypeTexture()` 還能用 `showAlways` 與 `stealableFilter` 控制顯示。`showAlways = true` 會直接顯示該材質，不再檢查 helpful／harmful、驅散類型或可偷取狀態；若目標是只標示可偷取光環，應單獨使用：

```lua
local Stealable = button:CreateTexture(nil, "OVERLAY")
Stealable:SetAllPoints()
Stealable:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Stealable")

button:AddDispelTypeTexture(Stealable, {
    style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
    showWhenHelpful = true,
    showWithoutDispelType = true,
    stealableFilter = Enum.CustomAuraButtonDispelTypeStealableFilter.Stealable,
})
```

另外可在 `PostCreateButton` 增加 12.1 原生功能，例如 pandemic 狀態：

```lua
local function PostCreateButton(element, button, options)
    local Pandemic = button:CreateTexture(nil, "OVERLAY")
    Pandemic:SetAllPoints()
    Pandemic:SetColorTexture(0.2, 1, 0.2, 0.22)

    button:AddPandemicRegion(Pandemic)
    button.Pandemic = Pandemic
end
```

顯示／隱藏會由 AuraButton 原生更新，不需要 aura update callback。

### 1.10 完全自訂 `CreateButton`

若只要改外觀，優先使用 oUF 預設建立流程加 `PostCreateButton`。只有需要替換整套子元件時才覆寫 `CreateButton`。

14.0.0 的簽名與舊版完全不同：

```lua
local function CreateButton(element, options, button)
    -- 初始化由原生容器已建立的 AuraButton。
    -- 不要再 CreateFrame 一個新 Button，也不需要 return button。
end
```

完整範例：

```lua
local function CreateButton(element, options, button)
    local size = options.size or element.size or 24
    local width = options.width or element.width or size
    local height = options.height or element.height or size

    button:SetSize(width, height)
    button:EnableMouse(not (options.disableMouse or element.disableMouse))
    button:SetTooltipAnchorPoint("ANCHOR_BOTTOMLEFT", 0, 0)
    button:SetHideTooltipInCombat(false)

    local Icon = button:CreateTexture(nil, "BORDER")
    Icon:SetAllPoints()
    Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.Icon = Icon
    button:SetIcon(Icon)

    local Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    Cooldown:SetAllPoints()
    button.Cooldown = Cooldown
    button:SetDurationCooldown(Cooldown)

    local TextLayer = CreateFrame("Frame", nil, button)
    TextLayer:SetAllPoints()
    TextLayer:SetFrameLevel(Cooldown:GetFrameLevel() + 1)

    local Count = TextLayer:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    Count:SetPoint("BOTTOMRIGHT", -1, 0)
    button.Count = Count
    button:SetApplicationCount(Count, {
        formatter = options.countFormatter or element.countFormatter,
    })

    local Time = TextLayer:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    Time:SetPoint("TOPLEFT", 1, 0)
    button.Time = Time
    button:SetDurationText(Time, {
        binding = options.durationBinding or element.durationBinding,
        textFormatter = options.durationFormatter or element.durationFormatter,
        textFormat = options.durationFormat or element.durationFormat,
        textColor = options.durationColors or element.durationColors,
    })

    local Border = button:CreateTexture(nil, "OVERLAY")
    Border:SetAllPoints()
    button.Border = Border
    button:AddDispelTypeTexture(Border, {
        style = Enum.CustomAuraButtonDispelTypeTextureStyle.Border,
        showWhenHarmful = true,
        showWhenHelpful = false,
        customDispelColorMap = element.__owner.colors.dispel,
    })

    if element.PostCreateButton then
        element:PostCreateButton(button, options)
    end
end

local Auras = self:CreateAuras({
    growthX = "RIGHT",
    growthY = "DOWN",
})
Auras.CreateButton = CreateButton
Auras:AddGroup("HARMFUL", { maxFrameCount = 12 })
```

覆寫後，下列責任都由 layout 承擔：

- 按鈕大小與 mouse 狀態。
- tooltip 設定。
- icon binding。
- cooldown binding。
- application count binding。
- duration text／bar binding。
- dispel／stealable／pandemic 顯示。
- cancel aura clicks。
- 是否繼續呼叫 `PostCreateButton`。

不要直接設定 `options.initializeFrame`，除非要完全跳過 oUF 的 `CreateButton` 與 `PostCreateButton` 流程。`options.CreateButton` 是 oUF 提供的 group／slot 級 override；`options.initializeFrame` 則是直接交給 Blizzard AuraContainer 的底層 callback。

### 1.11 舊 Auras 選項遷移表

| 13.4.5 | 14.0.0 |
| --- | --- |
| `self.Auras = CreateFrame(...)` | `local Auras = self:CreateAuras(options)` |
| `self.Buffs`／`self.Debuffs` | 一個容器內建立 HELPFUL／HARMFUL group，或建立兩個容器 |
| `.num` | group 的 `maxFrameCount` |
| `.numBuffs`／`.numDebuffs` | 各 group 的 `maxFrameCount` |
| `.numTotal` | 無跨 group 的共用總上限；需重新分配每組上限 |
| `.buffFilter`／`.debuffFilter`／`.filter` | `AddGroup(filter, options)` 的 `filter` 參數 |
| 動態 filter function | 保存 key，呼叫 `SetAuraGroupFilterString()`／`SetAuraSlotFilterString()` |
| `.onlyShowPlayer` | `HELPFUL|PLAYER`，或 `candidateFilters.isFromPlayerOrPlayerPet = true` |
| `.showStealableBuffs` | `.showStealableBorder = true` |
| `.showType` | 依需求設定 `showBuffBorder`、`showDebuffBorder` 或 indicator |
| `.showBuffType`／`.showDebuffType` | `.showBuffBorder`／`.showDebuffBorder` |
| `.spacingX`／`.spacingY` | 橫向 layout 通常對應 `elementSpacing`／`lineSpacing`；直向時軸向相反 |
| `.maxCols` | 以 `layoutLimit`、按鈕尺寸與 spacing 控制換行 |
| `.reanchorIfVisibleChanged` | 原生 flow layout 自動處理 |
| `.gap` | 使用 `groupSpacing`、`groupLineSpacing` 或 `forceNewLine` |
| `.minCount`／`.maxCount` | 使用 `countFormatter`；沒有相同的舊式 `"*"` 內建規則 |
| `.dispelColorCurve` | 原生 dispel texture；自訂顏色 map 使用字串 key |
| `button.auraInstanceID` | 不再作為 layout 公開狀態 |
| `button.isHarmfulAura` | 不再作為 layout 公開狀態 |

### 1.12 舊 Auras callback／override 遷移表

| 13.4.5 契約 | 14.0.0 狀態 | 遷移方式 |
| --- | --- | --- |
| `PostCreateButton(button)` | 改為 `PostCreateButton(button, options)` | 用於一次性外觀與原生 binding |
| `PostUpdateButton(button, unit, data, position)` | 移除 | 使用 AuraButton 原生 setter；不再把 AuraData 交給 Lua callback |
| `PostProcessAuraData(unit, data, filter)` | 移除 | 使用 processing policy 與 candidate filters |
| `PreUpdate(unit, isFullUpdate)` | 移除 | 沒有逐次更新替代 callback |
| `PostUpdateInfo(unit, ...)` | 移除 | 沒有逐次更新替代 callback |
| `PostUpdateGapButton(...)` | 移除 | 使用 group spacing／forceNewLine |
| `PostUpdate(unit)` | 移除 | 沒有逐次更新替代 callback |
| `CreateButton(position) -> button` | 改為 `CreateButton(options, button)` | 初始化既有 AuraButton；不回傳按鈕 |
| `FilterAura(unit, data, filter)` | 移除 | filter string、candidate filters、processing policy |
| `SortAuras`／`SortBuffs`／`SortDebuffs` | 移除 | `sortMethod`／`sortDirection` |
| `SetPosition(from, to)` | 移除 | `CreateAuras` 與 group `layout` 選項 |

### 1.13 Auras 安全邊界

14.0.0 不提供逐光環 Lua callback 是設計決策，不是漏掉功能。12.1 的 AuraContainer／AuraButton 會把受限資料留在原生更新路徑；layout 應提供「要顯示什麼」與「用哪些原生 widget 顯示」，而不是重新取得 AuraData 做 Lua 判斷。

尤其不要用下列方式模擬舊 callback：

- 從 AuraButton 數量推算實際光環數。
- 在 `OnShow`／`OnHide`／`OnSizeChanged` 追蹤光環變化。
- hook AuraButton 的私有更新函式。
- 重新監聽 `UNIT_AURA` 並建立第二套 cache。
- 從原生 widget 讀回文字、數值或顯示狀態，再反推 aura 資料。

加入 aura group 後，容器會禁止不受信任的 layout script；依賴 `OnSizeChanged` 的舊排版或計數邏輯需要移除。

## 2. Unit frame 狀態欄位改名

核心的 unit 相關 Lua 欄位改名：

| 13.4.5 | 14.0.0 | 說明 |
| --- | --- | --- |
| `frame.unit` | `frame.__unit` | oUF 當前實際顯示的 unit，包含 vehicle 切換結果 |
| `frame.realUnit` | `frame.__realUnit` | secure button 的原始 unit；通常只在 modified unit 情境使用 |
| `frame.id` | `frame.__unitIndex` | unit token 尾端索引；新值是 number，而舊 `.id` 是字串 |

自製 element 的典型更新：

```lua
-- 13.4.5
if self.unit ~= unit then return end

-- 14.0.0
if self.__unit ~= unit then return end
```

```lua
-- 13.4.5
Path(element.__owner, "ForceUpdate", element.__owner.unit)

-- 14.0.0
Path(element.__owner, "ForceUpdate", element.__owner.__unit)
```

callback 已經提供 `unit` 時，優先使用 callback 參數，不要再從 owner 讀一次。

`frame:GetAttribute("unit")` 是 secure unit button 的 attribute，不一定等同 oUF 經 vehicle／modified unit 計算後的 `frame.__unit`，不能無條件拿來替換 `frame.unit`。

其他核心狀態替換：

| 舊用法 | 新用法 |
| --- | --- |
| `frame.__eventless` | `frame:IsEventless()` |
| 直接修改 `frame.__elements` | 使用 `oUF:AddElement()`／`oUF:AddMetaElement()` |
| 直接檢查 `frame.__tags` | 使用 `Tag()`、`Untag()`、`UpdateTags()` |
| tag FontString 的 `fs.parent` | tag method 內使用 `_FRAME`；核心 owner 現為 `fs.__owner` |

## 3. Castbar callback 與時間顯示

### 3.1 callback 簽名變更

| callback | 13.4.5 | 14.0.0 |
| --- | --- | --- |
| `PostCastStart` | `(unit)` | `(unit, spellID, notInterruptible, name, texture, isTradeSkill)` |
| `PostCastUpdate` | `(unit)` | `(unit, spellID, duration, direction)` |
| `PostCastInterrupted` | `(unit, interruptedBy)` | `(unit, spellID, interruptedBy)` |
| `PostCastStop` | `(unit, empowerComplete)` | `(unit, spellID, empowerComplete)` |
| `PostCastFail` | `(unit)` | `(unit, spellID)` |
| `PostCastInterruptible` | `(unit)` | `(unit, spellID, notInterruptible)` |
| `PostCastGlobal` | 不存在 | `(unit, spellID, cooldownInfo, duration)` |
| `PostUpdatePips` | `(stages)` | 不變 |

所有在第二個或第三個位置插入參數的 callback 都必須重新檢查；Lua 不會因函式參數名稱不同而報錯，舊程式可能靜默把 `spellID` 當成 `interruptedBy` 或 `empowerComplete`。

14.0.0 把原本公開在 Castbar 上的暫存欄位改為內部狀態，包括：

- `castID`
- `casting`
- `channeling`
- `empowering`
- `notInterruptible`
- `spellID`
- `spellName`
- `delay`
- `startTime`
- `endTime`
- `holdTime`

需要的公開資料改由 callback 傳入。不要在 callback 之外輪詢這些欄位。

### 3.2 `.Time` 改用 `DurationTextBinding`

`CustomTimeText(duration)` 已移除。只要提供 `Castbar.Time`，oUF 會建立或使用 `Time.binding`，把施法的 `DurationObject` 綁到 FontString。

最簡單的自訂方式是只提供 formatter：

```lua
local formatter = C_StringUtil.CreateSecondsFormatter()
formatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)
formatter:SetMinInterval(Enum.SecondsFormatterInterval.Seconds)
formatter:SetMillisecondsThreshold(60)

local Time = Castbar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
Time:SetPoint("RIGHT", Castbar)
Time.formatter = formatter
Castbar.Time = Time
```

需要「當前進度／總時間」時，直接提供 binding：

```lua
local formatter = C_StringUtil.CreateSecondsFormatter()
formatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)
formatter:SetMinInterval(Enum.SecondsFormatterInterval.Seconds)
formatter:SetMillisecondsThreshold(60)

local binding = C_DurationUtil.CreateDurationTextBinding()
binding:SetTextFormat("{}/{}", {
    {
        property = Enum.DurationTextBindingProperty.ElapsedDuration,
        formatter = formatter,
    },
    {
        property = Enum.DurationTextBindingProperty.TotalDuration,
        formatter = formatter,
    },
})

local Time = Castbar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
Time:SetPoint("RIGHT", Castbar)
Time.binding = binding
Castbar.Time = Time
```

可用 property 包括 `ElapsedDuration`、`RemainingDuration`、`TotalDuration`。binding 必須在 Castbar element 啟用前設定；oUF 會負責綁定 FontString、更新 duration 及啟用／停用 binding。

### 3.3 `.Delay` 與 `CustomDelayText`

延遲文字不再覆寫 `.Time`，而是使用獨立 FontString：

```lua
local Delay = Castbar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
Delay:SetPoint("LEFT", Castbar)
Castbar.Delay = Delay
```

新版 override：

```lua
function Castbar:CustomDelayText(delay, isChanneling)
    self.Delay:SetFormattedText("%s%.2f", isChanneling and "-" or "+", delay)
end
```

沒有建立 `.Delay` 時，`CustomDelayText` 不會被呼叫。舊 `CustomDelayText(duration)` 接收 DurationObject 並改寫 `.Time` 的實作不能原封不動沿用。

### 3.4 Global cooldown

玩家 Castbar 可以設定：

```lua
Castbar.showGlobalCooldown = true
```

oUF 會在沒有真實施法時，用施法條顯示 GCD，並呼叫：

```lua
function Castbar:PostCastGlobal(unit, spellID, cooldownInfo, duration)
end
```

此選項只對 player element 註冊事件。

## 4. ClassPower callback 與顏色 override

### 4.1 `PostUpdate` 插入參數

```lua
-- 13.4.5
function ClassPower:PostUpdate(cur, max, hasMaxChanged, powerType, ...)
end

-- 14.0.0
function ClassPower:PostUpdate(cur, max, hasCurChanged, hasMaxChanged, powerType, ...)
end
```

`hasCurChanged` 插在第三個位置，因此 `hasMaxChanged`、`powerType` 與 charged point indices 都會右移。

14.0.0 原始碼的 callback 標題仍顯示舊短簽名，但實際呼叫為：

```lua
element:PostUpdate(cur, max, hasCurChanged, hasMaxChanged, powerType, ...)
```

### 4.2 `UpdateColor` override 改為標準 element path

```lua
-- 13.4.5：self 是 ClassPower element
function ClassPower:UpdateColor(powerType)
end

-- 14.0.0：self 是 unit frame
ClassPower.UpdateColor = function(self, event, unit)
    local element = self.ClassPower
end
```

新版不再把 `powerType` 傳給 `UpdateColor` override。需要資源類型時，優先使用 `PostUpdate(..., powerType, ...)`；只要對最終顏色做外觀處理時，使用未變更的 `PostUpdateColor(color)`。

下列 ClassPower 暫存欄位已內部化，不再讀取：

- `__powerType`
- `__powerID`
- `__max`
- `__cur`
- `__isEnabled`

## 5. HealthPrediction 與 PowerPrediction 移除

兩個 element 在 13.4.5 已標為 deprecated，14.0.0 正式刪除並從 `oUF.xml` 移除。

### 5.1 HealthPrediction -> Health 子元件

| 舊欄位 | 新欄位 |
| --- | --- |
| `HealthPrediction.healingAll` | `Health.HealingAll` |
| `HealthPrediction.healingPlayer` | `Health.HealingPlayer` |
| `HealthPrediction.healingOther` | `Health.HealingOther` |
| `HealthPrediction.overHealIndicator` | `Health.OverHealIndicator` |
| `HealthPrediction.damageAbsorb` | `Health.DamageAbsorb` |
| `HealthPrediction.overDamageAbsorbIndicator` | `Health.OverDamageAbsorbIndicator` |
| `HealthPrediction.healAbsorb` | `Health.HealAbsorb` |
| `HealthPrediction.overHealAbsorbIndicator` | `Health.OverHealAbsorbIndicator` |

範例：

```lua
local Health = CreateFrame("StatusBar", nil, self)
Health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
Health:SetAllPoints()

local HealingAll = CreateFrame("StatusBar", nil, Health)
HealingAll:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
HealingAll:SetPoint("TOP")
HealingAll:SetPoint("BOTTOM")
HealingAll:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT")
HealingAll:SetWidth(Health:GetWidth())
Health.HealingAll = HealingAll

local DamageAbsorb = CreateFrame("StatusBar", nil, Health)
DamageAbsorb:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
DamageAbsorb:SetPoint("TOP")
DamageAbsorb:SetPoint("BOTTOM")
DamageAbsorb:SetPoint("LEFT", HealingAll:GetStatusBarTexture(), "RIGHT")
DamageAbsorb:SetWidth(Health:GetWidth())
Health.DamageAbsorb = DamageAbsorb

self.Health = Health
```

prediction clamp 選項也改放在 `Health`：

- `maximumHealthClampMode`
- `damageAbsorbClampMode`
- `healAbsorbClampMode`
- `healAbsorbMode`
- `incomingHealClampMode`
- `incomingHealOverflow`

舊 `HealthPrediction:PreUpdate()`／`PostUpdate()` 不再存在。一般外觀更新使用 `Health:PreUpdate(unit)`／`Health:PostUpdate(unit, cur, max, lossPerc)`；calculator 保存在 `Health.values`。

### 5.2 PowerPrediction -> Power／AdditionalPower 子元件

| 舊欄位 | 新欄位 |
| --- | --- |
| `PowerPrediction.mainBar` | `Power.CostPrediction` |
| `PowerPrediction.altBar` | `AdditionalPower.CostPrediction` |

```lua
local CostPrediction = CreateFrame("StatusBar", nil, Power)
CostPrediction:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
CostPrediction:SetReverseFill(true)
CostPrediction:SetPoint("TOP")
CostPrediction:SetPoint("BOTTOM")
CostPrediction:SetPoint("RIGHT", Power:GetStatusBarTexture(), "RIGHT")
CostPrediction:SetWidth(Power:GetWidth())
Power.CostPrediction = CostPrediction
```

callback 拆成：

```lua
function Power:PostUpdatePrediction(unit, cost)
end

function AdditionalPower:PostUpdatePrediction(unit, cost)
end
```

舊 `PowerPrediction:PostUpdate(unit, mainCost, altCost, hasAltManaBar)` 沒有一對一的新 callback。

## 6. Totems callback 改用 DurationObject

```lua
-- 13.4.5
function Totems:PostUpdate(slot, haveTotem, name, start, duration, icon, durationObj)
end

-- 14.0.0
function Totems:PostUpdate(slot, haveTotem, name, icon, duration)
    -- duration 是 DurationObject
end
```

舊數字型 `start` 與總秒數 `duration` 已移除；新 `duration` 是 `GetTotemDuration()` 回傳的 `DurationObject`。

Cooldown 應使用：

```lua
totem.Cooldown:SetCooldownFromDurationObject(duration)
```

文字倒數應使用 `DurationTextBinding`，不要把 DurationObject 轉回 Lua 秒數後自行逐幀運算。

## 7. PhaseIndicator callback 精簡

```lua
-- 13.4.5
function PhaseIndicator:PostUpdate(isInSamePhase, phaseReason)
end

-- 14.0.0
function PhaseIndicator:PostUpdate(phaseReason)
end
```

`UnitPhaseReason()` 回傳 secret value 時，oUF 會把 `phaseReason` 改為 nil。因此 nil 可能表示同相位，也可能表示 addon 無法安全取得原因；不要用 `phaseReason == nil` 重建一個強保證的 `isInSamePhase`。

需要外觀同步時，以 element 已由 oUF 設定好的顯示狀態為準；callback 主要用於補充樣式。

## 8. ReadyCheckIndicator 移除 deprecated 設定

已移除：

- `readyTexture`
- `notReadyTexture`
- `waitingTexture`
- `status` 暫存欄位

oUF 現在每次更新都套用 Blizzard atlas。需要自訂貼圖時，在未變更簽名的 `PostUpdate(status)` 中覆蓋最終外觀；需要狀態時使用 callback 參數，不要讀 `element.status`。

仍保留：

- `finishedTime`
- `fadeTime`
- `useAtlasSize`
- `PostUpdate(status)`
- `PostUpdateFadeOut()`

## 9. DispelType enum 與顏色 key

`oUF.Enum.DispelType` 已移除。

```lua
-- 13.4.5
local magic = oUF.colors.dispel[oUF.Enum.DispelType.Magic]

-- 14.0.0
local magic = oUF.colors.dispel.Magic
```

14.0.0 的 `oUF.colors.dispel` 由 `AuraUtil.GetDebuffDisplayInfoTable()` 建立，使用名稱 key：

- `None`
- `Magic`
- `Curse`
- `Disease`
- `Poison`
- `Bleed`
- `Enrage`

自訂 `customDispelColorMap` 也應使用相同字串 key。

## 10. Element 暫存狀態內部化

14.0.0 把大量更新狀態移到每個 element 檔案的私有 `STATE` table。下列舊欄位即使曾經可讀，也不再是可依賴的資料來源：

| element | 已內部化的常見欄位 |
| --- | --- |
| `AdditionalPower` | `cur`、`max`、cost、prediction size、visibility state |
| `AlternativePower` | `cur`、`min`、`max`、`__barID`、`__barInfo` |
| `Castbar` | cast/channel/empower、spell、delay、time、hold state |
| `ClassPower` | power type／ID、cur／max、visibility state |
| `Health` | deprecated `cur`／`max`、prediction size state |
| `Portrait` | `guid`、`state` |
| `Power` | `cur`、`min`、`max`、`displayType`、cost state |
| `ReadyCheckIndicator` | `status` |
| `Stagger` | `cur`、`max` |
| `Tags` | `frame.__tags`、`fs.parent` 與全域 tagged FontString cache |

遷移原則：

1. 更新當下需要值：使用 callback 參數。
2. 顯示數值：使用 oUF 已提供的 widget、calculator、DurationObject 或 binding。
3. 需要強制刷新：使用 element 的 `ForceUpdate()`。
4. 需要判斷 element 狀態：使用公開的 `IsElementEnabled()`、`IsElementPaused()` 或 element 顯示 API。
5. 不要把新 `STATE` table 複製到 layout 內維護第二份狀態。

另外，已 deprecated 的下列方法正式移除：

```lua
Health:SetColorDisconnected(...)
Power:SetColorDisconnected(...)
```

在建立 element 前直接設定 `colorDisconnected`；若執行期變更，修改 option 後呼叫 `ForceUpdate()`。

## 11. Eventless tags 更新頻率

13.4.5 會讓 eventless unit 上的每個 tag 依自己的 `FontString.frequentUpdates` 建立 timer。14.0.0 改為直接沿用 eventless unit frame 的全域更新 timer。

結果：

- 一般 unit frame 的 `fs.frequentUpdates` 行為不變。
- eventless unit（例如 `targettarget`）不再由 `fs.frequentUpdates` 覆蓋 frame timer。
- eventless unit 要改頻率，設定 `frame.onUpdateFrequency`，再重新交給 `oUF:HandleEventlessUnit(frame)` 登記。

```lua
local frame = oUF:Spawn("targettarget")
frame.onUpdateFrequency = 0.2
oUF:HandleEventlessUnit(frame)
```

## 12. Nameplate callback 與輔助欄位

Nameplate callback 的簽名沒有改，但觸發範圍改變：

```lua
nameplates:SetAddedCallback(function(nameplate, event, unit) end)
nameplates:SetRemovedCallback(function(nameplate, event, unit) end)
nameplates:SetTargetCallback(function(nameplate, event, unit) end)
```

- widgets-only nameplate 與 game object nameplate 不會觸發 Added／Target callback，oUF frame 會被隱藏並 pause 全部 elements。
- 14.0.0 的 Removed 路徑仍會在已有 oUF frame 時呼叫 Removed callback，因此不要假設每次 Removed 前一定收到過 Added。
- Blizzard 的 `nameplate.UnitFrame.WidgetContainer` 與 `SoftTargetFrame` 改為直接掛在原生 nameplate；oUF frame 不再提供 `frame.WidgetContainer`／`frame.SoftTargetFrame` 引用。
- `oUF:Spawn()` 與 `SpawnHeader()` 的直接 parent 改為 `UIParent`，可見性改由 roleset 管理。依賴舊 hidden parent 或自行改 parent 控制 pet battle 顯隱的程式需要移除。

一般只透過 callback 參數與自己的 element 工作的 nameplate layout 不需要修改；依賴上述舊欄位或把 Added／Removed 視為嚴格成對事件的程式則必須調整。

# Callback 使用指南

## 1. Callback 與 override 的差別

callback 用來在 oUF 完成預設更新後補充行為：

```lua
local function PostUpdate(element, unit, ...)
    -- element 是掛 callback 的 element。
end

Health.PostUpdate = PostUpdate
```

override 會取代 oUF 的更新函式：

```lua
Health.Override = function(self, event, unit)
    -- self 是 unit frame；事件、數值更新、顯示與安全性都由 layout 負責。
end
```

升級 14.0.0 時，優先把外觀邏輯放在 callback；只有預設 element 無法提供所需行為時才覆寫更新路徑。

## 2. Callback 的 `self`

oUF 大多以冒號呼叫 element callback：

```lua
element:PostUpdate(unit, value)
```

所以函式實際第一個參數永遠是 element：

```lua
local function PostUpdate(element, unit, value)
end
```

不要把它誤寫成 unit frame，除非該契約明確是 frame callback，例如 `frame:PreUpdate(event)`／`frame:PostUpdate(event)`。

Nameplate driver callback 是另一個明確例外：`SetAddedCallback()`、`SetRemovedCallback()`、`SetTargetCallback()` 保存的是普通函式，oUF 以 `callback(nameplateFrame, event, unit)` 呼叫；第一個參數是 nameplate unit frame，不是 driver，也沒有額外的隱含 `self`。

## 3. 不要依賴 callback return value

多個 element 會用 `return element:PostUpdate(...)` 結束內部函式，但 oUF 並沒有把 callback return value 定義成控制更新結果的契約。除非文件明確要求回傳值，callback 應只做 side effect。

## 4. Secret value 不會因 callback 而解密

oUF 把某個 API 值傳入 callback，不代表該值已變成公開值。12.1 中，health、power、cast、duration、aura 或 unit identity 等參數可能仍為 secret。

callback 中不要對可能為 secret 的值做：

- Lua 比較或 boolean test。
- 算術。
- table key／array index。
- 排序或篩選。
- `tonumber()`、字串解析或格式內容判斷。

應把值傳給明確支援 secret argument 的 widget setter、formatter、calculator 或 binding。Auras 只提供建立期 callback，正是為了讓 aura 資料持續留在原生 AuraButton 路徑。

## 5. Callback 遷移總表

| 模組 | 必須修改的契約 |
| --- | --- |
| Auras | 只保留 `PostCreateButton(button, options)`；其餘更新 callback 移除 |
| Castbar | 所有主要 cast callback 新增 `spellID`；start/update/interruptible 另增資料 |
| ClassPower | `PostUpdate` 新增第三參數 `hasCurChanged` |
| Totems | `PostUpdate` 改為 `(slot, haveTotem, name, icon, durationObject)` |
| PhaseIndicator | `PostUpdate` 改為只接收 `phaseReason` |
| HealthPrediction | element 與 callback 移除，改用 Health |
| PowerPrediction | element 與 callback 移除，改用 Power／AdditionalPower |
| ReadyCheckIndicator | callback 簽名不變，但不能再讀 `.status` |
| Nameplates | 簽名不變；Added／Target 會略過 widgets-only 與 game object，Removed 不保證有配對 Added |

# 非破壞性改動

## 1. 12.1 secret value 安全化

多個 element 改為避免直接比較或索引受限值，並把顯示交給支援 secret argument 的 API。主要變化包括：

- unit token 比較改用 `C_Secrets.CanCompareUnitTokens()` 後才呼叫 `UnitIsUnit()`。
- class 為 secret 時，Health、Power、Portrait 與 `[raidcolor]` 改用 Blizzard `C_ClassColor` 路徑。
- Assistant、Leader、GroupRole、RaidRole、PvP、Phase 等 indicator 增加 secret guard 或安全顯示方式。
- Health／Power 的值仍由 calculator 與 StatusBar setter 更新，不要求 layout 讀回 Lua 數值。
- Tags 對部分不可安全判斷的 metadata 會省略文字，而不是引發 Lua 錯誤。

對只使用公開 widget 與 callback 的 layout，這些通常不需要修改；自製 override 仍須自行維持相同安全邊界。

## 2. 新增 element pause／resume API

14.0.0 新增：

```lua
frame:PauseElement(name, unit)
frame:ResumeElement(name, unit)
frame:IsElementPaused(name)
frame:PauseAllElements()
frame:ResumeAllElements()
```

pause 會暫時執行 element 的 disable 路徑並停止更新，但保留 enabled 狀態；resume 重新執行 enable。它與永久的 `DisableElement()` 不同。

在 14.0.0 的實際實作中，paused element 仍會令 `IsElementEnabled(name)` 回傳 true，因此再次呼叫 `EnableElement(name)` 不會恢復它；請明確使用 `ResumeElement(name)` 或 `ResumeAllElements()`。

## 3. 新增 `oUF:AddMetaElement()`

```lua
oUF:AddMetaElement(name, create, update, enable, disable)
```

除了登記 element，還會把 `create` 註冊成所有 unit frame 可用的 `Create<name>()` meta function。新的 Auras 便以此提供 `frame:CreateAuras()`。

這適合需要由 layout 主動建立一個或多個實例、但仍希望由 oUF 統一 enable／disable／update 的擴充 element。

## 4. Nameplate 行為修正

對只建立一般 unit nameplate、且不讀取 oUF 內部欄位的 layout，以下屬於核心生命週期修正：

- widgets-only nameplate 與 game object nameplate 不再顯示 oUF unit frame。
- 這類非 unit 名條會 pause 所有 element，而不是繼續更新無效 unit。
- 名條移除時會先恢復被 pause 的 element 並重置可見性，供下一次重用。
- Blizzard nameplate frame 每次出現時都會重新停用其預設事件，避免重初始化把預設框架帶回來。

callback 簽名雖然不變，但特殊名條的 callback 配對與輔助欄位有破壞性差異，見「Nameplate callback 與輔助欄位」。

## 5. Blizzard frame 隱藏改用 rolesets

oUF 不再以 hidden parent、反覆 reparent 與 PetBattleFrameHider 隱藏 Blizzard unit frame，改用 12.1 的 `SetRolesets()`：

- oUF 一般 unit frame：`unitFrames`
- arena frame：`arenaFrames`
- 被停用的 Blizzard frame：`alwaysBlocked`

透過標準 `oUF:Spawn()`／`SpawnHeader()` 建立框架的 layout 不需要自行設定 roleset，也不應覆蓋 oUF 已選擇的 roleset。

## 6. Castbar 功能與穩定性

除破壞性 callback 變更外，Castbar 還有以下改善：

- 原生 `DurationObject` 與 `DurationTextBinding` 更新時間文字。
- 非玩家施法可使用新 API 提供的 delay 資料。
- 新增玩家 global cooldown 顯示。
- empowered cast 結束時間計算修正。
- 新施法開始前先清空舊狀態，避免殘留施法條。
- Delay 不再繼承或覆蓋 Time 的顏色與文字。

## 7. Tags 排程與內部狀態

- eventless tags 共用 unit frame 的 eventless timer，減少重複 OnUpdate。
- tag owner、已註冊 FontString 與 frame element update list 改為內部 table。
- `C_Secrets.CanCompareUnitTokens()` 取代以 `pcall(UnitIsUnit)` 探測可比較性。
- `[raidcolor]` 在 class 為 secret 時改用 Blizzard class color。

正常使用 `oUF.Tags.Methods`、`oUF.Tags.Events`、`frame:Tag()` 與 `_FRAME` 的自訂 tag 不需要改結構。

## 8. 其他 element 清理

- `oUF.toc` 的 Interface 清單由 `120005, 120007` 更新為 `120007, 120100`。若插件自行封裝 oUF、使用自己的 TOC，應同步加入 12.1 的 `120100`。
- `AdditionalPower`、`AlternativePower`、`Health`、`Power`、`Portrait`、`Stagger` 等 element 的 callback 公開簽名基本不變，主要是內部 state 與 secret-safe 更新重整。
- GroupRoleIndicator 改用 enum 版本 API。
- SummonIndicator、RaidTargetIndicator、Power 類 element 不再保存容易過期的 Enum／API upvalue。
- ReadyCheckIndicator 統一使用 Blizzard atlas。
- `DisableBlizzard()` 的外部呼叫方式不變。

# 建議升級順序

1. 先更新 oUF library 與載入清單，確認 `healthprediction.lua`、`powerprediction.lua` 不再被引用。
2. 全面改寫 Auras；不要在舊 `CreateFrame` 結構上局部修補。
3. 搜尋並修改 unit state：`.unit`、`.realUnit`、`.id`、`.__eventless`。
4. 依 callback 總表逐一調整參數位置，特別是 Castbar、ClassPower、Totems。
5. 把施法時間改成 `.Time.binding`／`.Time.formatter`，把 pushback 改成 `.Delay`。
6. 把 prediction widget 搬到 Health／Power／AdditionalPower。
7. 移除 `oUF.Enum.DispelType` 與所有數字型 dispel color key。
8. 移除對 element 暫存欄位與 tag 私有 table 的讀取。
9. 在一般野外、隊伍／團隊、載具、競技場準備、名條、戰鬥 lockdown 與 secret value 環境分別測試。

# 建議搜尋項目

升級時可全專案搜尋下列識別字：

```text
PostUpdateButton
PostProcessAuraData
PostUpdateInfo
PostUpdateGapButton
FilterAura
SortAuras
SortBuffs
SortDebuffs
SetPosition
CustomTimeText
CustomDelayText
HealthPrediction
PowerPrediction
SetColorDisconnected
readyTexture
notReadyTexture
waitingTexture
oUF.Enum.DispelType
.unit
.realUnit
.id
.__eventless
.__elements
.__tags
.parent
```

`.unit`、`.id`、`.parent` 等名稱很常見，搜尋後要逐一確認是否真的屬於 oUF frame／tag FontString，不能機械式全域替換。

# 驗證清單

- [ ] 所有 aura 容器都由 `CreateAuras()` 建立。
- [ ] `PostCreateButton` 在任何 `AddGroup()`／`AddSlot()` 之前指定。
- [ ] 沒有 callback 依賴 AuraData、button 數量或容器尺寸推算 aura 狀態。
- [ ] 每個 group／slot 都有明確 filter、上限、排序與 layout。
- [ ] `numTotal` 舊邏輯已重新設計，而不是被遺漏。
- [ ] Castbar callback 參數沒有錯位。
- [ ] Castbar `.Time` 使用 binding／formatter，`.Delay` 獨立顯示。
- [ ] ClassPower `hasCurChanged` 已加入第三個位置。
- [ ] Totems 使用 DurationObject。
- [ ] HealthPrediction／PowerPrediction 已完全移除。
- [ ] 自製 element 使用 `__unit` 或 callback unit。
- [ ] 沒有讀取已內部化的 element state。
- [ ] 所有 callback 都按 12.1 secret value 規則檢查資料流。

# 來源

- [oUF 13.4.5...14.0.0 compare](https://github.com/oUF-wow/oUF/compare/13.4.5...14.0.0)
- [oUF 14.0.0 Auras](https://github.com/oUF-wow/oUF/blob/14.0.0/elements/auras.lua)
- [oUF 14.0.0 Castbar](https://github.com/oUF-wow/oUF/blob/14.0.0/elements/castbar.lua)
- [oUF 14.0.0 ClassPower](https://github.com/oUF-wow/oUF/blob/14.0.0/elements/classpower.lua)
- [oUF 14.0.0 core](https://github.com/oUF-wow/oUF/blob/14.0.0/ouf.lua)
- [Blizzard CustomAuraContainer](https://github.com/BigWigsMods/WoWUI/blob/live/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua)
- [Blizzard CustomAuraButton](https://github.com/BigWigsMods/WoWUI/blob/live/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua)
