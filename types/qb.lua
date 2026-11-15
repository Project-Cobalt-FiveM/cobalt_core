---@meta

---@class QbPlayerMetadata : PlayerMetadata
---@field injail integer
---@field jailitems table
---@field tracker boolean
---@field inside { apartment: table }
---@field phone table
---@field phonedata { SerialNumber: string, InstalledApps: table }
---@field commandbinds table
---@field dealerrep integer
---@field craftingrep integer
---@field attachmentcraftingrep integer

---cobalt_core's player data with qb-core's metadata defaults and `job.payment` filled in.
---@class QbPlayerData : PlayerData
---@field metadata QbPlayerMetadata

---@class QbPlayerFunctions : PlayerFunctions
local QbPlayerFunctions = {}

---@return QbPlayerData
function QbPlayerFunctions.GetPlayerData() end

function QbPlayerFunctions.UpdateClient() end

---@param job string
---@param grade? integer|string
---@return boolean
function QbPlayerFunctions.SetJob(job, grade) end

---@param gang string
---@param grade? integer|string
---@return boolean
function QbPlayerFunctions.SetGang(gang, grade) end

---@param onDuty boolean
---@return boolean
function QbPlayerFunctions.SetJobDuty(onDuty) end

---@param items string|string[]|table<string, integer>
---@param amount? integer
---@return boolean
function QbPlayerFunctions.HasItem(items, amount) end

---@param item string
---@param amount? integer
---@param slot? integer ignored
---@param info? table
---@param reason? string
---@return boolean
function QbPlayerFunctions.AddItem(item, amount, slot, info, reason) end

---@param item string
---@param amount? integer
---@param slot? integer ignored
---@param reason? string
---@return boolean
function QbPlayerFunctions.RemoveItem(item, amount, slot, reason) end

---@param item string
---@return table?
function QbPlayerFunctions.GetItemByName(item) end

---**Server.** A qb-core shaped snapshot of a `CorePlayer`. It has no methods of its own: call `Player.Functions.Name(...)`.
---@class QbPlayer
---@field PlayerData QbPlayerData
---@field Functions QbPlayerFunctions
---@field Offline boolean

---@class QbMoneyConfig
---@field MoneyTypes table<string, integer>
---@field DontAllowMinus string[]
---@field MinusLimit integer
---@field PayCheckTimeOut integer minutes
---@field PayCheckSociety boolean

---@class QbConfig : table<string, any>
---@field Money QbMoneyConfig

---`QBCore.Player`: cobalt_core's player module, with getters that return qb-core shaped players.
---@class QbPlayerModule : PlayerModule
local QbPlayerModule = {}

---The character with this citizenid, online or loaded from `players`.
---@param citizenid string
---@return QbPlayer?
function QbPlayerModule.GetOfflinePlayer(citizenid) end

---The character on this Rockstar license, online or else the license's character whose row changed last.
---@param license string
---@return QbPlayer?
function QbPlayerModule.GetPlayerByLicense(license) end

---The same lookup as `GetPlayerByLicense`.
---@param license string
---@return QbPlayer?
function QbPlayerModule.GetOfflinePlayerByLicense(license) end

---@return string
function QbPlayerModule.CreateSerialNumber() end

---`Functions` of the qb-core core object: cobalt_core's, with player getters that return qb-core shaped players.
---@class QbFunctions : Functions
local QbFunctions = {}

---**Client.** The local character's data in qb-core's shape.
---@return QbPlayerData
function QbFunctions.GetPlayerData() end

---**Client.**
---@param cb fun(data: QbPlayerData)
function QbFunctions.GetPlayerData(cb) end

---**Client.**
---@param items string|string[]|table<string, integer>
---@param amount? integer
---@return boolean
function QbFunctions.HasItem(items, amount) end

---**Server.**
---@param source integer
---@param items string|string[]|table<string, integer>
---@param amount? integer
---@return boolean
function QbFunctions.HasItem(source, items, amount) end

---**Server.**
---@param source? integer|string
---@return QbPlayer?
function QbFunctions.GetPlayer(source) end

---**Server.** The online player with this citizenid. Reads memory only, as qb-core does.
---@param citizenid string
---@return QbPlayer?
function QbFunctions.GetPlayerByCitizenId(citizenid) end

---**Server.** The character with this citizenid, online or loaded from `players`, through cobalt_core's `GetPlayerByCitizenId`.
---@param citizenid string
---@return QbPlayer?
function QbFunctions.GetOfflinePlayerByCitizenId(citizenid) end

---**Server.** The online player on this Rockstar license, or else the license's character whose row changed last, loaded from `players` as qb-core does.
---@param license string
---@return QbPlayer?
function QbFunctions.GetPlayerByLicense(license) end

---**Server.** The online player whose npwd number in `players.phone_number` is `number`. Reads memory only.
---@param number string
---@return QbPlayer?
function QbFunctions.GetPlayerByPhone(number) end

---**Server.** The first online player whose `charinfo[property]` equals `value`. Reads memory only.
---@param property string charinfo key
---@param value string|number
---@return QbPlayer?
function QbFunctions.GetPlayerByCharInfo(property, value) end

---**Server.**
---@param account string
---@return QbPlayer?
function QbFunctions.GetPlayerByAccount(account) end

---**Server.**
---@return table<integer, QbPlayer>
function QbFunctions.GetQBPlayers() end

---**Server.**
---@return string
function QbFunctions.CreateAccountNumber() end

---**Server.**
---@return string
function QbFunctions.CreatePhoneNumber() end

---**Server.** Runs the useable-item handler registered for an item.
---@param source integer
---@param item string|{ name: string }
function QbFunctions.UseItem(source, item) end

---The table `exports['qb-core']:GetCoreObject()` returns.
---@class QbCore : Core
---@field Functions QbFunctions
---@field Config QbConfig
---@field PlayerData QbPlayerData
---@field Players table<integer, QbPlayer>
---@field Player QbPlayerModule

---`exports['qb-core']`, served by cobalt_core's qb bridge. Each export is tagged with the side it exists on.
---@class CobaltQbExports
local CobaltQbExports = {}

---**Client.**
---@param filters? string[]
---@return QbCore
function CobaltQbExports:GetCoreObject(filters) end

---**Server.**
---@param filters? string[]
---@return QbCore
function CobaltQbExports:GetCoreObject(filters) end

---**Shared.** cobalt_inventory's item definitions.
---@return table<string, InventoryItemDef>
function CobaltQbExports:GetSharedItems() end

---**Shared.**
---@return table<string, SharedVehicle>
function CobaltQbExports:GetSharedVehicles() end

---**Shared.**
---@return table<integer, { name: string, label: string }> cobalt_inventory's weapon items keyed by hash
function CobaltQbExports:GetSharedWeapons() end

---**Shared.**
---@return table<string, CoreJobDefinition>
function CobaltQbExports:GetSharedJobs() end

---**Shared.**
---@return table<string, GangDefinition>
function CobaltQbExports:GetSharedGangs() end

---**Shared.** One entry of a `Cobalt.Shared` table, or one cobalt_inventory item definition for `Items`.
---@param namespace 'Vehicles'|'VehicleHashes'|'Items'|'Gangs'|'Jobs'|'Locations'|'Weapons'
---@param item string|integer
---@return any
function CobaltQbExports:GetShared(namespace, item) end

---**Client.** Shows text UI.
---@param text string
---@param position? 'left'|'right'|'top'
function CobaltQbExports:DrawText(text, position) end

---**Client.** Same as `DrawText`.
---@param text string
---@param position? 'left'|'right'|'top'
function CobaltQbExports:ChangeText(text, position) end

---**Client.** Hides text UI.
function CobaltQbExports:HideText() end

---**Client.** Hides text UI.
function CobaltQbExports:KeyPressed() end

---**Server.**
---@param playerId integer
---@param origin string ban reason
function CobaltQbExports:ExploitBan(playerId, origin) end

---**Client.** Registers a callback the server can trigger; the handler replies through `cb`.
---@param name string
---@param cb fun(reply: fun(...), ...)
function CobaltQbExports:CreateClientCallback(name, cb) end

---**Client.** Calls a server callback. Pass a function first to get the result asynchronously; otherwise it yields and returns the result.
---@param name string
---@param ... any
---@return ...
function CobaltQbExports:TriggerCallback(name, ...) end

---**Client.** The local character's full name.
---@return string
function CobaltQbExports:GetName() end

---**Client.**
---@return boolean
function CobaltQbExports:IsWearingGloves() end

---**Client.**
---@return integer[]
function CobaltQbExports:GetVehicles() end

---**Client.**
---@return integer[]
function CobaltQbExports:GetObjects() end

---**Client.** Active player indices.
---@return integer[]
function CobaltQbExports:GetPlayers() end

---**Server.** Server ids of loaded players.
---@return integer[]
function CobaltQbExports:GetPlayers() end

---**Client.**
---@param coords? vector3
---@param distance? number
---@return integer[] players player indices
function CobaltQbExports:GetPlayersFromCoords(coords, distance) end

---**Client.**
---@param coords? vector3
---@return integer player player index, -1 when none
---@return number distance
function CobaltQbExports:GetClosestPlayer(coords) end

---**Client.**
---@param ignoreList? integer[]
---@return integer[]
function CobaltQbExports:GetPeds(ignoreList) end

---**Client.**
---@param coords? vector3
---@param ignoreList? integer[]
---@return integer ped
---@return number distance
function CobaltQbExports:GetClosestPed(coords, ignoreList) end

---**Client.**
---@param coords? vector3
---@return integer vehicle
---@return number distance
function CobaltQbExports:GetClosestVehicle(coords) end

---**Client.**
---@param coords? vector3
---@return integer object
---@return number distance
function CobaltQbExports:GetClosestObject(coords) end

---**Client.** Yields until the model is loaded.
---@param model integer|string
function CobaltQbExports:LoadModel(model) end

---**Server.** Spawns a vehicle with `CreateVehicleServerSetter`, with a random plate and full fuel.
---@param source integer
---@param model integer|string
---@param coords? vector3|vector4
---@param warp? boolean
---@param vehicleType? string
---@return integer? vehicle
---@return string? plate
function CobaltQbExports:SpawnVehicle(source, model, coords, warp, vehicleType) end

---**Client.**
---@param vehicle integer
---@return string?
function CobaltQbExports:GetPlate(vehicle) end

---**Client.**
---@param vehicle integer
---@return string?
function CobaltQbExports:GetVehicleLabel(vehicle) end

---**Client.**
---@param vehicle integer
---@return CoreVehicleProperties?
function CobaltQbExports:GetVehicleProperties(vehicle) end

---**Client.**
---@param vehicle integer
---@param props CoreVehicleProperties
function CobaltQbExports:SetVehicleProperties(vehicle, props) end

---**Client.** Draws world text for one frame.
---@param x number
---@param y number
---@param z number
---@param text string
function CobaltQbExports:DrawText3D(x, y, z, text) end

---**Client.** Yields until the dictionary is loaded.
---@param animDict string
function CobaltQbExports:RequestAnimDict(animDict) end

---**Client.**
---@param ped integer
---@param model integer|string
---@param boneId integer
---@param x number
---@param y number
---@param z number
---@param xR number
---@param yR number
---@param zR number
---@param vertex? boolean
---@return integer prop
function CobaltQbExports:AttachProp(ped, model, boneId, x, y, z, xR, yR, zR, vertex) end

---**Client.**
---@param animSet string
function CobaltQbExports:LoadAnimSet(animSet) end

---**Client.**
---@param dictionary string
function CobaltQbExports:LoadParticleDictionary(dictionary) end

---**Client.**
---@param coords vector3
---@return StreetName
function CobaltQbExports:GetStreetNametAtCoords(coords) end

---**Client.**
---@param coords vector3
---@return string
function CobaltQbExports:GetZoneAtCoords(coords) end

---**Client.**
---@param entity integer
---@return integer materialHash
---@return integer entityHit
---@return vector3 surfaceNormal
---@return vector3 endCoords
---@return boolean success
---@return integer retval
function CobaltQbExports:GetGroundHash(entity) end

---**Client.** Shows a notification through cobalt_interfaces.
---@param text string|InterfaceNotifyProps
---@param notifyType? NotifyType
---@param length? integer milliseconds
---@param icon? string
function CobaltQbExports:Notify(text, notifyType, length, icon) end

---**Server.** Shows a notification to one player, or every player with -1.
---@param source integer
---@param data string|InterfaceNotifyProps
---@param notifyType? NotifyType
---@param length? integer milliseconds
function CobaltQbExports:Notify(source, data, notifyType, length) end

---**Client.** Yields and returns true when the bar fills.
---@param data CoreProgressProps
---@return boolean
function CobaltQbExports:Progressbar(data) end

---**Client.** QBCore's positional form: returns at once, then calls `onFinish` or `onCancel`.
---@param name string
---@param label string
---@param duration integer milliseconds
---@param useWhileDead? boolean
---@param canCancel? boolean
---@param disableControls? table
---@param animation? table
---@param prop? table
---@param propTwo? table
---@param onFinish? fun()
---@param onCancel? fun()
function CobaltQbExports:Progressbar(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel) end

---**Client.**
---@param text string
---@param options? InterfaceTextUIOptions
function CobaltQbExports:ShowTextUI(text, options) end

---**Client.**
function CobaltQbExports:HideTextUI() end

---**Client.**
---@return boolean open
---@return string? text
function CobaltQbExports:IsTextUIOpen() end

---**Client.** Yields until the check ends.
---@param difficulty SkillCheckDifficulity|SkillCheckDifficulity[]
---@param inputs? string[]
---@return boolean?
function CobaltQbExports:SkillCheck(difficulty, inputs) end

---**Client.**
---@param context ContextMenu|ContextMenu[]
function CobaltQbExports:RegisterContext(context) end

---**Client.**
---@param id string
function CobaltQbExports:ShowContext(id) end

---**Client.**
---@param onExit? boolean runs the menu's onExit
function CobaltQbExports:HideContext(onExit) end

---**Client.** Yields until the dialog closes.
---@param heading string
---@param rows (string|InputRow)[]
---@param options? InputOptions
---@return any[]?
function CobaltQbExports:InputDialog(heading, rows, options) end

---**Client.** Yields until the dialog closes.
---@param data AlertProps
---@param timeout? integer milliseconds
---@return 'confirm'|'cancel'|nil
function CobaltQbExports:AlertDialog(data, timeout) end

---**Client.**
---@param items InterfaceRadialItem|InterfaceRadialItem[]
function CobaltQbExports:AddRadialItem(items) end

---**Client.**
---@param id string
function CobaltQbExports:RemoveRadialItem(id) end

---**Client.**
---@param menu RadialMenu
function CobaltQbExports:RegisterRadial(menu) end

---**Client.**
function CobaltQbExports:HideRadial() end

---**Client.**
---@param state boolean
function CobaltQbExports:DisableRadial(state) end

---**Server.**
---@param source integer
---@param idtype? 'license'|'license2'|'discord'|'steam'|'fivem'|'xbl'|'live'|'ip'|string
---@return string?
function CobaltQbExports:GetIdentifier(source, idtype) end

---**Server.** The loaded player holding an identifier, or 0.
---@param identifier string
---@return integer
function CobaltQbExports:GetSource(identifier) end

---**Server.** Online players whose cobalt_management job (`PlayerData.job`) has this name or type, and their count.
---@param job string job name or type
---@param checkOnDuty? boolean only players on duty
---@return integer[] players
---@return integer count
function CobaltQbExports:GetPlayersByJob(job, checkOnDuty) end

---**Server.** QBCore's count of on-duty players in the job with this name or type, then their server ids.
---@param job string job name or type
---@return integer count
---@return integer[] sources
function CobaltQbExports:GetDutyCount(job) end

---**Server.**
---@return table<integer, { id: integer, bucket: integer }> players
---@return table<integer, { id: integer, bucket: integer }> entities
function CobaltQbExports:GetBucketObjects() end

---**Server.**
---@param source integer
---@param bucket integer
---@return boolean
function CobaltQbExports:SetPlayerBucket(source, bucket) end

---**Server.**
---@param entity integer
---@param bucket integer
---@return boolean
function CobaltQbExports:SetEntityBucket(entity, bucket) end

---**Server.**
---@param bucket integer
---@return integer[]|false
function CobaltQbExports:GetPlayersInBucket(bucket) end

---**Server.**
---@param bucket integer
---@return integer[]|false
function CobaltQbExports:GetEntitiesInBucket(bucket) end

---**Server.** Calls a client callback. Pass a function first to get the result asynchronously; otherwise it yields and returns the result.
---@param name string
---@param source integer
---@param ... any
---@return ...
function CobaltQbExports:TriggerClientCallback(name, source, ...) end

---**Server.** Registers a callback clients can trigger; the handler replies through `cb`.
---@param name string
---@param cb fun(source: integer, reply: fun(...), ...)
function CobaltQbExports:CreateCallback(name, cb) end

---**Server.**
---@param item string
---@param data fun(source: integer, item: table)|{ cb?: function, callback?: function }
function CobaltQbExports:CreateUseableItem(item, data) end

---**Server.**
---@param item string
---@return UseableItem?
function CobaltQbExports:CanUseItem(item) end

---**Server.**
---@param source integer
---@param reason string
---@param setKickReason? fun(reason: string)
---@param deferrals? table
function CobaltQbExports:Kick(source, reason, setKickReason, deferrals) end

---**Server.**
---@param source integer
---@return boolean
function CobaltQbExports:IsWhitelisted(source) end

---**Server.**
---@param source integer
---@param permission string
function CobaltQbExports:AddPermission(source, permission) end

---**Server.**
---@param source integer
---@param permission string
function CobaltQbExports:RemovePermission(source, permission) end

---**Server.**
---@param source integer
---@param permission string|string[]
---@return boolean
function CobaltQbExports:HasPermission(source, permission) end

---**Server.**
---@param source integer
---@return table<string, boolean>
function CobaltQbExports:GetPermission(source) end

---**Server.**
---@param source integer
---@return boolean
function CobaltQbExports:IsOptin(source) end

---**Server.**
---@param source integer
function CobaltQbExports:ToggleOptin(source) end

---**Server.**
---@param source integer
---@return boolean banned
---@return string? message
function CobaltQbExports:IsPlayerBanned(source) end

---**Server.**
---@param license string
---@return boolean
function CobaltQbExports:IsLicenseInUse(license) end

---**Server.** Adds a method to every player object.
---@param methodName string
---@param handler fun(self: CorePlayer, ...): ...
---@return boolean ok
---@return string message
function CobaltQbExports:SetMethod(methodName, handler) end

---**Server.** Adds a field to the core object.
---@param fieldName string
---@param data any
---@return boolean ok
---@return string message
function CobaltQbExports:SetField(fieldName, data) end

---**Server.**
---@param jobName string
---@param job CoreJobDefinition
---@return boolean ok
---@return OrgResult message
function CobaltQbExports:AddJob(jobName, job) end

---**Server.**
---@param jobs table<string, CoreJobDefinition>
---@return boolean ok
---@return string message
function CobaltQbExports:AddJobs(jobs) end

---**Server.**
---@param jobName string
---@return boolean ok
---@return OrgResult message
function CobaltQbExports:RemoveJob(jobName) end

---**Server.**
---@param jobName string
---@param job CoreJobDefinition
---@return boolean ok
---@return OrgResult message
function CobaltQbExports:UpdateJob(jobName, job) end

---**Server.**
---@param gangName string
---@param gang GangDefinition
---@return boolean ok
---@return OrgResult message
function CobaltQbExports:AddGang(gangName, gang) end

---**Server.**
---@param gangs table<string, GangDefinition>
---@return boolean ok
---@return string message
function CobaltQbExports:AddGangs(gangs) end

---**Server.**
---@param gangName string
---@return boolean ok
---@return OrgResult message
function CobaltQbExports:RemoveGang(gangName) end

---**Server.**
---@param gangName string
---@param gang GangDefinition
---@return boolean ok
---@return OrgResult message
function CobaltQbExports:UpdateGang(gangName, gang) end

---**Server.**
---@param invokingResource? string printed with the version when given
---@return string
function CobaltQbExports:GetCoreVersion(invokingResource) end

---**Server.** Adds a method to one player, a list of players, or every player with -1.
---@param ids integer|integer[]
---@param methodName string
---@param handler fun(self: CorePlayer, ...): ...
function CobaltQbExports:AddPlayerMethod(ids, methodName, handler) end

---**Server.** Adds a field to one player, a list of players, or every player with -1.
---@param ids integer|integer[]
---@param fieldName string
---@param data any
function CobaltQbExports:AddPlayerField(ids, fieldName, data) end

---**Client.** The local character's data in qb-core's shape.
---@return QbPlayerData
function CobaltQbExports:GetPlayerData() end

---**Client.**
---@param cb fun(data: QbPlayerData)
function CobaltQbExports:GetPlayerData(cb) end

---**Client.**
---@param items string|string[]|table<string, integer>
---@param amount? integer
---@return boolean
function CobaltQbExports:HasItem(items, amount) end

---**Server.**
---@param source integer
---@param items string|string[]|table<string, integer>
---@param amount? integer
---@return boolean
function CobaltQbExports:HasItem(source, items, amount) end

---**Server.**
---@param source? integer|string
---@return QbPlayer?
function CobaltQbExports:GetPlayer(source) end

---**Server.** The online player with this citizenid. Reads memory only, as qb-core does.
---@param citizenid string
---@return QbPlayer?
function CobaltQbExports:GetPlayerByCitizenId(citizenid) end

---**Server.** The character with this citizenid, online or loaded from `players`, through cobalt_core's `GetPlayerByCitizenId`.
---@param citizenid string
---@return QbPlayer?
function CobaltQbExports:GetOfflinePlayerByCitizenId(citizenid) end

---**Server.** The online player on this Rockstar license, or else the license's character whose row changed last, loaded from `players` as qb-core does.
---@param license string
---@return QbPlayer?
function CobaltQbExports:GetPlayerByLicense(license) end

---**Server.** The online player whose npwd number in `players.phone_number` is `number`. Reads memory only.
---@param number string
---@return QbPlayer?
function CobaltQbExports:GetPlayerByPhone(number) end

---**Server.** The first online player whose `charinfo[property]` equals `value`. Reads memory only.
---@param property string charinfo key
---@param value string|number
---@return QbPlayer?
function CobaltQbExports:GetPlayerByCharInfo(property, value) end

---**Server.**
---@param account string
---@return QbPlayer?
function CobaltQbExports:GetPlayerByAccount(account) end

---**Server.**
---@return table<integer, QbPlayer>
function CobaltQbExports:GetQBPlayers() end

---**Server.**
---@return string
function CobaltQbExports:CreateAccountNumber() end

---**Server.**
---@return string
function CobaltQbExports:CreatePhoneNumber() end

---**Server.** Runs the useable-item handler registered for an item.
---@param source integer
---@param item string|{ name: string }
function CobaltQbExports:UseItem(source, item) end

exports['qb-core'] = CobaltQbExports
