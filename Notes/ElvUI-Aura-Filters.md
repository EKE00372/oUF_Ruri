# ElvUI 光環過濾器說明

本文以 Retail 12.1 的 AuraContainer 路徑為基準，說明 ElvUI 如何組合光環過濾器，以及對使用 AuraContainer 的插件開發者有哪些可借鑑之處。

## 結論

ElvUI 並不是只使用 Blizzard 原生 filter。它採用混合方式：

1. 使用原生 `filterString` 做大分類。
2. 使用原生 `candidateFilters` 做光環欄位過濾。
3. 使用法術 ID 黑名單與白名單處理已知例外。
4. 使用多個 AuraGroup 分層顯示不同優先級的光環。
5. 使用 AuraWatch 或指示器補足少數重要技能。

Retail 12.1 的主要流程是：

```text
ElvUI filterLists
    -> UF:GroupFilters
    -> candidateFilters / filterString
    -> E:Auras_SetContainer
    -> AuraContainer:AddAuraGroup / AddAuraSlot
```

ElvUI 舊版的 `priority`、`UF:ConvertFilters()`、`UF:CheckFilter()` 仍存在，但它們屬於舊式 AuraFilter 路徑。Retail AuraContainer 主要使用 `filterLists`。

## ElvUI 的預設過濾器

### 玩家、隊伍與團隊增益

常見的預設組合是：

```lua
HELPFUL|BIG_DEFENSIVE|PLAYER|!EXTERNAL_DEFENSIVE
HELPFUL|EXTERNAL_DEFENSIVE
```

第一組顯示玩家自己施放的大型減傷，並排除外援減傷。第二組顯示其他玩家施放的外援減傷。

### 玩家、隊伍與團隊減益

ElvUI 會把減益分成數個 group：

```lua
HARMFUL|IMPORTANT
HARMFUL|RAID_PLAYER_DISPELLABLE
HARMFUL|CROWD_CONTROL
HARMFUL|RAID|!RAID_PLAYER_DISPELLABLE
HARMFUL
```

最後一組通常再搭配：

```lua
isPriorityAura = true
excludeSpellIDs = Blacklist
```

實際設定會依單位不同而調整。例如玩家、隊伍與團隊通常會顯示重要減益、可由團隊驅散的減益、控場，以及經過黑名單排除後的團隊減益。

### 目標與焦點增益

目標與焦點會額外使用原生 candidate 欄位：

```lua
isBossOrRoleAura = true
isStealable = true
isFromPlayerOrPlayerPet = true
```

這些設定分別用於首領／職責光環、可偷取光環，以及玩家自己或寵物施放的光環。

### 目標與競技場減益

常見配置包括：

```lua
HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY
HARMFUL|CROWD_CONTROL
```

第一組用於自身施放的目標減益，並配合 `nameplateShowPersonal`；第二組用於控場效果。

## ElvUI 的黑名單與白名單

ElvUI 有全域的自訂光環過濾器：

- `Blacklist`：排除疲勞、競速、坐騎、無關緊要的系統光環等雜訊。
- `Whitelist`：保證顯示復活、戰復、Power Infusion、Innervate 等少數重要技能。

只有 group 設定 `useBlocklist` 或 `useAllowlist` 時，這些名單才會被轉換成：

```lua
candidateFilters.excludeSpellIDs
candidateFilters.includeSpellIDs
```

它們不是自動套用到所有光環的全域規則。

## `||` 與原生 `|`

ElvUI 設定檔常看到這種寫法：

```lua
HELPFUL||BIG_DEFENSIVE||PLAYER
```

目前 Blizzard UI 的 filter parser 會忽略連續分隔符產生的空元件，因此這種寫法的有效效果等同於：

```lua
HELPFUL|BIG_DEFENSIVE|PLAYER
```

這不是 OR 語法。多個 filter component 仍然是同時成立的條件，也就是 AND。Ruri 自己建立 filter string 時應使用標準的單一 `|`。

## Blizzard 原生 filter 的限制

原生 filter 適合做大分類，但不能完整表達插件自己的戰術需求。

### Blizzard 分類可能遺漏技能

`IMPORTANT`、`BIG_DEFENSIVE`、`CROWD_CONTROL` 等分類由 Blizzard 維護。插件不能自行把某個法術標記成 `BIG_DEFENSIVE` 或 `IMPORTANT`。

`RAID` 與 `RAID_PLAYER_DISPELLABLE` 也只代表 Blizzard 定義的可施放／可驅散範圍，不等於所有實戰上重要的光環。

### `includeSpellIDs` 不會覆蓋原始 filter

例如：

```lua
HELPFUL|BIG_DEFENSIVE
```

如果某個技能沒有被 Blizzard 標記為大型減傷，即使把它加入 `includeSpellIDs`，也不會通過前面的 `BIG_DEFENSIVE` 條件。

要補進這種技能，必須改用較寬的原生 filter，例如：

```lua
HELPFUL
```

再用 `includeSpellIDs` 限定法術，或建立獨立的 AuraGroup／AuraSlot。

### 法術 ID 過濾受到 secret 限制

AuraContainer 只允許在特定情況使用 `includeSpellIDs` 與 `excludeSpellIDs`：

- 友方單位的 helpful aura。
- 敵方單位的 harmful aura。
- Blizzard 標記為 `NeverSecret` 的例外光環。

友方單位的 harmful aura，以及敵方單位的 helpful aura，可能跳過法術 ID candidate 過濾。這是 Blizzard 的安全限制，不是 ElvUI 遺漏功能。

因此對友方單位的 secret debuff，不能假設 ElvUI 黑名單一定能依照法術 ID 隱藏。

### 沒有單一 Group 內的自訂法術優先級

Group 的 `sortMethod` 只能使用 AuraContainer 提供的排序方式，例如 `Default`、`BigDefensive`、`Expiration`、`ImportantOnly` 等。

它不能表示：

```text
法術 A 優先於法術 B，法術 B 優先於其他所有光環
```

需要固定優先級時，應使用獨立的 AuraSlot 或互相排他的 AuraGroup。

## 給 Ruri 的建議

Ruri 不需要完整複製 ElvUI 的五組減益配置。每個 AuraGroup 都會增加按鈕池與版面管理成本，而且重疊的 filter 可能讓同一個光環符合多個 group。

建議採用以下原則：

1. 以原生 filter 作為第一層大分類，維持 secret-safe。
2. 以少量靜態法術 ID 表處理已知雜訊與例外。
3. 一般單位控制在 2～3 個主要 AuraGroup。
4. 少量高優先級法術使用 `AddAuraSlot()`，避免為一個例外建立完整 group。
5. 不重新實作 `UnitAura` 輪詢或 Lua `CustomFilter` 來取代 AuraContainer。

可作為基礎的分類如下：

```lua
-- 玩家自身大型減傷
HELPFUL|BIG_DEFENSIVE|PLAYER|!EXTERNAL_DEFENSIVE

-- 外援減傷
HELPFUL|EXTERNAL_DEFENSIVE

-- 重要減益
HARMFUL|IMPORTANT

-- 團隊可驅散減益
HARMFUL|RAID_PLAYER_DISPELLABLE

-- 控場減益
HARMFUL|CROWD_CONTROL
```

如果要顯示一個沒有被 Blizzard 分類的敵方減益，可以使用：

```lua
container:AddAuraSlot('customSpell', 'HARMFUL', {

	candidateFilters = {
		includeSpellIDs = {
			[spellID] = true,
		},
	},
})
```

但這種法術 ID 方式仍須符合 AuraContainer 的 secret 限制。對友方 secret harmful aura，不能把它當成可靠的精確白名單方案。

總結而言，最適合 Ruri 的策略是：

> 原生 filter 作為主分類，靜態法術表作為例外，AuraSlot 處理少量高優先級技能，避免自行建立 secret 不安全的 AuraFilter。

## 參考來源

- ElvUI `Game/Shared/Modules/UnitFrames/Elements/Auras.lua`
- ElvUI `Game/Shared/Modules/Auras/Containers.lua`
- ElvUI `Game/Shared/Defaults/Profile.lua`
- Blizzard UI `AddOns/Blizzard_FrameXMLUtil/AuraUtil.lua`
- Blizzard UI `AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua`
- Blizzard UI `AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua`
