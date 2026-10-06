# oUF 名條預熱補丁

這是 Ruri 對官方 oUF 唯一一項**名條預熱擴充**，不是另一份 oUF 分支。遊戲只載入 `oUF_Ruri/Libs/oUF/ouf.lua`；本目錄供日後更新核心時核對、重新套用，不會被 TOC 載入。下方命令相對倉庫根目錄，插件源碼相對 `oUF_Ruri/`。

- 上游基準：oUF-wow/oUF `0f029b26e429ccbf9f60da60e7d89884775e000b`。
- 原始 `ouf.lua` blob：`b380e1ab6eca40797f892a5bca11919717b4917c`。
- 補丁只改 `oUF_Ruri/Libs/oUF/ouf.lua`：新增 `driver:Prewarm(create)`，以及首次 `NAME_PLATE_UNIT_ADDED` 的預建框接管分支；`.patch` 內路徑相對插件目錄，由工具加上 `--directory=oUF_Ruri`。
- 目標為 WoW MAINLINE 12.1；本次契約核對使用 WoWUI `origin/live` 的 `12.1.0.69933`／`9180cf72767951aeb095b57f0f0d7b1c367dc3b1`。

## 更新官方 oUF 時

1. 先保存尚未提交的本機修改，再依原本方式更新 `oUF_Ruri/Libs/oUF`。不要連本補丁目錄一起覆蓋。
2. 在專案根目錄執行 Python 工具（需要 Python 3.7 以上及 Git，不需額外套件）：

   ```cmd
   python Patches/apply-nameplate-prewarm.py --check
   python Patches/apply-nameplate-prewarm.py
   ```

   雙擊或從終端執行時，顯示結果後會等待按 Enter 才結束，成功、失敗與 `--check` 都適用。自動化可加 `--no-pause` 略過等待；非互動輸入也不會停住。

   `--check` 只回報狀態，不寫入或備份。一般執行會先辨識是否已套用；已套用時直接成功結束。可套用時，先將原始核心逐位元備份到已忽略的 `Tools/NameplatePrewarm/backups/`，核對 SHA-256，再以 `git apply` 套用，最後做反向完整性檢查。工具依自身位置定位專案，不依賴目前命令列目錄；`.patch` 仍是唯一補丁內容來源。原檔使用 LF 或 CRLF 都會保留，不受全域 Git 換行設定影響；混用兩種換行時停止，交由人工核對。

3. 若檢查失敗，工具以非零結束碼停止，不強制套用。部分套用或上游改動同一區段時，重新核對 `initObject`、`walkObject`、名條 ADDED／REMOVED 與 Auras 的 owner／STATE 契約後，調整補丁及上游基準。工具只會修改 `oUF_Ruri/Libs/oUF/ouf.lua`，不下載、不同步官方核心、不操作 Git 暫存區或提交。
4. 即使補丁套用成功，也要執行本機生命週期測試及遊戲內測試；文字套用成功不代表新版契約相容。

每次同步後以 `--check` 回報的實際狀態為準。也可從倉庫根目錄手動使用 `git apply --directory=oUF_Ruri --check Patches/oUF-nameplate-prewarm.patch` 和 `git apply --directory=oUF_Ruri Patches/oUF-nameplate-prewarm.patch`；手動執行不包含 Python 工具的自動備份。

## 分工與不可破壞的契約

- `Prewarm(create)` 一次只建立一張隱藏的普通 Button，使用與官方名條相同的 `PingableUnitFrameTemplate`。它不是 `SecureUnitButtonTemplate`，也不使用假 `nameplateN` 或 `RegisterUnitWatch`。
- oUF 負責根框架、待接管池和正式初始化入口。Ruri 的 `Core/Nameplates.lua` 負責外觀、預建總數與排程：延遲 2 秒、每 0.1 秒一張、總共 30 張，戰鬥中暫停背景建立。這不是可見名條上限，也不在消耗後無限補滿。
- 預建 callback 只建立外觀，不能註冊 Tag、單位事件或啟用 oUF element。AuraContainer 使用原生未綁定狀態並停用；首批 Group／AuraButton 外觀仍由官方 initialize callback 完成，不在之後遍歷受限制的按鈕。
- 真實名條出現時接管整張 owner，只對根框架執行一次 `initObject`；不能 `walkObject` 它的外觀子框，也不能把 AuraContainer 搬給另一張 owner。Ruri style 重用既有外觀，再綁定 StackingBounds、Tag，最後由原本 oUF 流程啟用 element 並更新。
- 空池時保留官方冷建立；已接管的框架跟隨原生名條重用，REMOVED 不將它退回預熱池。Widgets／SoftTarget、widgets-only 與 game-object 分支仍由官方流程處理。
- 沒有更換材質、改動尺寸／錨點、減少光環 Group 或加入 secret value 判斷。只有名條 Health／條形 Castbar 不再以 unit token 命名，改成無名子框；本專案沒有依賴這些舊全域名稱的 caller。

## 驗證與限制

補丁工具測試：`python -B Tools/NameplatePrewarm/test-patch-tool.py`。只在本專案 `Tools/NameplatePrewarm/` 下的隔離副本測試；14 個案例涵蓋唯讀檢查、備份、重複執行、衝突／部分套用、既有修改、目標範圍、缺檔、UTF-8、LF／CRLF、CRLF 補丁配 LF 核心，以及官方 14.1.0 套用與反套後逐位元還原。14.1.0 案例唯讀使用本機 `D:/Github/oUF` 的同名 tag。

本機測試位於已忽略的 `Tools/NameplatePrewarm/`，載入實際 oUF 初始化／事件／Auras 與 Ruri 建立函式，以 mock 原生 widget 檢查 owner、單次初始化、預建階段無 unit 查詢、兩種樣式、功能開關、空池、暫停／恢復和重用。它不模擬真實引擎的 secret／taint、protected parent、FrameLevel 傳播或繪製。

遊戲內需測登入／Reload、預熱未完就進戰、戰鬥中首次接管、超過預備量的大量名條、玩家／NPC 與 widgets-only 重用，以及光環、施法環、高亮、吸收盾和堆疊位置。預熱只前移建立成本；真實 SetUnit、光環解析、布局與繪製成本仍在，不能保證完全消除 FPS drop。
