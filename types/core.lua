---@meta

---@alias MoneyType 'cash'|'bank'|'crypto'|string
---@alias LogLevel 'debug'|'info'|'warn'|'error'|'fatal'|'security'
---@alias NotifyType 'primary'|'inform'|'info'|'success'|'warning'|'warn'|'error'
---@alias OrgResult 'success'|'invalid_job_name'|'job_exists'|'job_not_exists'|'invalid_gang_name'|'gang_exists'|'gang_not_exists'|'invalid_method_name'|'invalid_field_name'

---@class CharInfo
---@field firstname string
---@field lastname string
---@field birthdate string
---@field gender 0|1
---@field nationality string
---@field phone? string
---@field account? string

---@class Grade
---@field name string
---@field level integer
---@field payment? integer
---@field isboss? boolean

---@class Job
---@field name string
---@field label string
---@field type? 'none'|'leo'|'ems'|'mechanic'|string
---@field onduty boolean
---@field isboss boolean
---@field grade Grade

---@class Gang
---@field name string
---@field label string
---@field isboss boolean
---@field grade Grade

---@class TempJob
---@field name string
---@field label string
---@field data table?
---@field resource string the resource that set it; the job clears when that resource stops

---@class LicenseType
---@field label string
---@field pointsLimit? integer points that revoke it, missing for a licence without points

---@class LicenseRecord
---@field held boolean
---@field grantedAt? integer unix time of the grant, missing for grants made before it was recorded
---@field grantedBy? string who granted it, such as `LSPD` or `the DMV`
---@field revokedAt? integer unix time of the last revocation, while it is not held
---@field points integer points on it, kept after the points limit revokes it and cleared by a new grant
---@field pointsLimit? integer

---@class CardItemMetadata
---@field citizenid string
---@field firstname string
---@field lastname string
---@field birthdate string `YYYY-MM-DD`
---@field gender integer 0 male, 1 female
---@field nationality string
---@field licence? string the licence key, such as `driver` or `weapon`; missing on an ID card
---@field issued string `YYYY-MM-DD`, the day the card was made

---@class CardData
---@field style 'american' | 'lebanese'
---@field kind 'id' | string `id`, or a licence key such as `driver` or `weapon`
---@field holder integer server id of the card's holder, for the headshot
---@field citizenid string
---@field firstname string
---@field lastname string
---@field birthdate? string `YYYY-MM-DD`
---@field gender? integer 0 male, 1 female
---@field nationality? string
---@field issued? string `YYYY-MM-DD`, the day the card was bought
---@field grantedBy? string who granted the licence
---@field grantedAt? integer unix time of the grant

---@class CriminalRecord
---@field hasRecord boolean
---@field date? string

---@class Licences
---@field driver boolean
---@field business boolean
---@field weapon boolean

---@class PlayerMetadata
---@field cash integer
---@field hunger number 0 to 100
---@field thirst number 0 to 100
---@field stress number
---@field isdead boolean
---@field inlaststand boolean
---@field armor number
---@field ishandcuffed boolean set while cobalt_police has the character restrained
---@field optin boolean admins with this on receive player reports
---@field status table
---@field rep table<string, integer>
---@field callsign string
---@field bloodtype string
---@field fingerprint string
---@field walletid string
---@field criminalrecord CriminalRecord
---@field licences Licences
---@field starterApartment? string
---@field job? Job cobalt_management's job; `players.job_name` indexes its name
---@field gang? Gang cobalt_management's gang; `players.gang_name` indexes its name
---@field secondjobs table<string, table> cobalt_management's second jobs, keyed by job name
---@field [string] any

---@class PlayerData
---@field source? integer nil on a character loaded from the database
---@field citizenid string
---@field license string
---@field phone_number? string the number npwd stored in `players.phone_number`, nil until npwd gives the character one
---@field stateid integer the player's permanent number across all their characters, issued in join order; also on the player's replicated `cobalt:stateid` state bag
---@field name string
---@field cid integer
---@field charinfo CharInfo
---@field money table<MoneyType, integer>
---@field job? Job the same table as `metadata.job`; SetMetaData sets both
---@field gang? Gang the same table as `metadata.gang`; SetMetaData sets both
---@field metadata PlayerMetadata
---@field position vector3|vector4
---@field [string] any

---@class JobGradeDefinition
---@field name string
---@field payment integer
---@field isboss? boolean

---@class CoreJobDefinition
---@field label string
---@field type? 'leo'|'ems'|'mechanic'
---@field society? boolean
---@field defaultDuty boolean
---@field offDutyPay boolean
---@field grades table<string, JobGradeDefinition>

---@class GangGradeDefinition
---@field name string
---@field isboss? boolean

---@class GangDefinition
---@field label string
---@field society? boolean
---@field grades table<string, GangGradeDefinition>

---@class SharedVehicle
---@field model string
---@field spawncode string
---@field name string
---@field brand string
---@field price integer
---@field category string vehicle class name, such as 'compacts' or 'super'
---@field class? integer GTA vehicle class number of `category`, 0 to 22; nil for a category GTA has no class for
---@field type string vehicle type, such as 'automobile' or 'boat'
---@field hash integer
---@field shops? string[] dealerships that sell it; without it, every dealership selling its category does
---@field shop? string[] same as shops, for qb-core scripts
---@field image? string dealership preview image for add-on cars
---@field enabled? boolean false stops dealerships selling it

---@class Shared
---@field Jobs table<string, CoreJobDefinition>
---@field Gangs table<string, GangDefinition>
---@field Vehicles table<string, SharedVehicle>
---@field VehicleHashes table<integer, SharedVehicle>
---@field Locations table
---@field ForceJobDefaultDutyAtLogin boolean
---@field MaleNoGloves table<integer, true>
---@field FemaleNoGloves table<integer, true>
local Shared = {}

---@param length integer
---@return string
function Shared.RandomStr(length) end

---@param length integer
---@return string
function Shared.RandomInt(length) end

---@param str string
---@param delimiter string
---@return string[]
function Shared.SplitStr(str, delimiter) end

---@param value string
---@return string
function Shared.Trim(value) end

---@param value string
---@return string
function Shared.FirstToUpper(value) end

---@param value number
---@param numDecimalPlaces? integer
---@return number
function Shared.Round(value, numDecimalPlaces) end

---@param vehicle integer
---@param extra integer
---@param enable boolean
function Shared.ChangeVehicleExtra(vehicle, extra, enable) end

---@param value any
---@return boolean
function Shared.IsFunction(value) end

---@param vehicle integer
---@param config table<string|integer, boolean>
function Shared.SetDefaultVehicleExtras(vehicle, config) end

---@class SharedConfig
---@field pvp boolean
---@field forceDefaultDutyAtLogin boolean
---@field money { starting: table<string, integer> }
---@field status { hungerRate: number, thirstRate: number, decayMinutes: number, starvingDamageSeconds: number }
---@field licenses table<string, LicenseType>
---@field idCard { style: 'american' | 'lebanese', showNearby: boolean, nearbyDistance: number, requireFacing: boolean, autoCloseSeconds: integer, viewerCloseSeconds: integer }
---@field stateIdPreview { key: string, radius: number }
---@field starterApartment { enabled: boolean, shell: string, locations: { id: string, label: string, description: string, door: vector4 }[] }

---@class ServerConfig
---@field closed boolean
---@field closedReason string
---@field whitelist boolean
---@field whitelistPermission string
---@field checkDuplicateLicense boolean
---@field spawn vector4 where a new character first loads in
---@field callbackLimit { perSecond: integer, floodSeconds: integer }
---@field migrations table<string, string[]> SQL files to create by resource, for resources whose file is not sql/<resource>.sql
---@field discord string
---@field permissions string[]
---@field logging LoggingConfig

---@class LoggingConfig
---@field enabled boolean
---@field minLevel 'debug'|'info'|'warn'|'error'|'fatal'
---@field environment string
---@field playerIdentifiers boolean
---@field console boolean
---@field disabled string[] categories, or category prefixes, that are not sent

---@class CommandArgument
---@field name string
---@field help string

---@class Commands
---@field List table<string, table>
---@field IgnoreList table<string, boolean>
local Commands = {}

---**Server.** Registers a chat command gated by an ACE permission.
---@param name string|string[]
---@param help string
---@param arguments CommandArgument[]
---@param argsrequired boolean
---@param callback fun(source: integer, args: string[], rawCommand: string)
---@param permission? 'user'|'staff'|'admin'|'owner'|string
---@param ... string extra permissions that may also run the command
function Commands.Add(name, help, arguments, argsrequired, callback, permission, ...) end

---**Server.** Resends the command suggestions a player may use.
---@param source integer
function Commands.Refresh(source) end

---@class PlayerFunctions
local PlayerFunctions = {}

---Sends the whole PlayerData to the client, or only the listed top-level fields.
---@param fields? string[]
function PlayerFunctions.UpdatePlayerData(fields) end

---@param text string|table
---@param type? NotifyType
---@param length? integer
function PlayerFunctions.Notify(text, type, length) end

---@return string?
function PlayerFunctions.GetName() end

---Sets one field, or several from a `{ [field] = value }` table, and sends only those to the client.
---@param key string | table<string, any>
---@param val? any
function PlayerFunctions.SetPlayerData(key, val) end

---Sets one metadata key in memory and sends it to the client; the next save writes it. `job` and `gang` also set `PlayerData.job` and `PlayerData.gang`.
---@param meta string
---@param val any
function PlayerFunctions.SetMetaData(meta, val) end

---@param meta string
---@return any
function PlayerFunctions.GetMetaData(meta) end

---@param rep string
---@param amount number
function PlayerFunctions.AddRep(rep, amount) end

---@param rep string
---@param amount number
function PlayerFunctions.RemoveRep(rep, amount) end

---@param rep string
---@return integer?
function PlayerFunctions.GetRep(rep) end

---@param moneytype MoneyType
---@param amount number
---@param reason? string
---@return boolean
function PlayerFunctions.AddMoney(moneytype, amount, reason) end

---@param moneytype MoneyType
---@param amount number
---@param reason? string
---@return boolean
function PlayerFunctions.RemoveMoney(moneytype, amount, reason) end

---@param moneytype MoneyType
---@param amount number
---@param reason? string
---@return boolean
function PlayerFunctions.SetMoney(moneytype, amount, reason) end

---@param moneytype MoneyType
---@return integer
function PlayerFunctions.GetMoney(moneytype) end

---@param balance integer
function PlayerFunctions.SyncBank(balance) end

function PlayerFunctions.Save() end

function PlayerFunctions.Logout() end

---@param methodName string
---@param handler fun(self: CorePlayer, ...): ...
function PlayerFunctions.AddMethod(methodName, handler) end

---@param fieldName string
---@param data any
function PlayerFunctions.AddField(fieldName, data) end

---**Server.** A loaded or offline character. Methods are on both `Player:Name(...)` and `Player.Functions.Name(...)`.
---@class CorePlayer
---@field PlayerData PlayerData
---@field Offline boolean
---@field deleted? boolean set once the character is deleted, so no save writes its row again
---@field Functions PlayerFunctions
local CorePlayer = {}

---Sends the whole PlayerData to the client, or only the listed top-level fields.
---@param fields? string[]
function CorePlayer:UpdatePlayerData(fields) end

---@param text string|table
---@param type? NotifyType
---@param length? integer
function CorePlayer:Notify(text, type, length) end

---@return string?
function CorePlayer:GetName() end

---Sets one field, or several from a `{ [field] = value }` table, and sends only those to the client.
---@param key string | table<string, any>
---@param val? any
function CorePlayer:SetPlayerData(key, val) end

---Sets one metadata key in memory and sends it to the client; the next save writes it. `job` and `gang` also set `PlayerData.job` and `PlayerData.gang`.
---@param meta string
---@param val any
function CorePlayer:SetMetaData(meta, val) end

---@param meta string
---@return any
function CorePlayer:GetMetaData(meta) end

---@param rep string
---@param amount number
function CorePlayer:AddRep(rep, amount) end

---@param rep string
---@param amount number
function CorePlayer:RemoveRep(rep, amount) end

---@param rep string
---@return integer?
function CorePlayer:GetRep(rep) end

---@param moneytype MoneyType
---@param amount number
---@param reason? string
---@return boolean
function CorePlayer:AddMoney(moneytype, amount, reason) end

---@param moneytype MoneyType
---@param amount number
---@param reason? string
---@return boolean
function CorePlayer:RemoveMoney(moneytype, amount, reason) end

---@param moneytype MoneyType
---@param amount number
---@param reason? string
---@return boolean
function CorePlayer:SetMoney(moneytype, amount, reason) end

---@param moneytype MoneyType
---@return integer
function CorePlayer:GetMoney(moneytype) end

---@param balance integer
function CorePlayer:SyncBank(balance) end

function CorePlayer:Save() end

function CorePlayer:Logout() end

---@param methodName string
---@param handler fun(self: CorePlayer, ...): ...
---@return boolean ok
---@return string? err
function CorePlayer:AddMethod(methodName, handler) end

---@param fieldName string
---@param value any
---@return boolean ok
---@return string? err
function CorePlayer:AddField(fieldName, value) end

---**Server.** `Cobalt.Player`: loading, saving and deleting characters.
---@class PlayerModule
local PlayerModule = {}

---@param source integer
---@param citizenid string|false false creates a character from `newData`
---@param newData? table
---@return boolean loaded false when the source already has a character loaded or is loading one
function PlayerModule.Login(source, citizenid, newData) end

---@param source integer
function PlayerModule.Logout(source) end

---Takes a character out of the citizenid, license and phone indexes and expires its cached offline copy.
---@param Player CorePlayer
function PlayerModule.Unindex(Player) end

---Records the number npwd stored in `players.phone_number` for a loaded character, in memory and on its client.
---@param citizenid string
---@param number string
function PlayerModule.SetPhoneNumber(citizenid, number) end

---@param source? integer nil for an offline character
---@param PlayerData? table
---@return CorePlayer?
function PlayerModule.CheckPlayerData(source, PlayerData) end

---@param PlayerData PlayerData
---@param Offline? boolean
---@return CorePlayer?
function PlayerModule.CreatePlayer(PlayerData, Offline) end

---@param source integer
function PlayerModule.Save(source) end

---@param PlayerData PlayerData
function PlayerModule.SaveOffline(PlayerData) end

---@param source integer
---@param citizenid string
---@return boolean deleted false when the caller doesn't own the character, it is loaded, or the delete rolled back
function PlayerModule.DeleteCharacter(source, citizenid) end

---@param citizenid string
---@return boolean deleted false when the character doesn't exist or the delete rolled back
function PlayerModule.ForceDeleteCharacter(citizenid) end

---Moves cash from one loaded character to another, writing both rows in one transaction.
---@param from CorePlayer
---@param to CorePlayer
---@param amount integer
---@param reason string
---@return boolean moved false when the giver holds less than `amount` or the write rolled back
function PlayerModule.TransferCash(from, to, amount, reason) end

---@return string
function PlayerModule.CreateCitizenId() end

---@return string
function PlayerModule.CreateFingerId() end

---@return string
function PlayerModule.CreateWalletId() end

---@class NearbyPlayer
---@field id integer
---@field ped integer
---@field coords vector3

---@class StreetName
---@field main string
---@field cross string

---@class UseableItem
---@field func function
---@field resource? string

---@alias CoreVehicleProperties table<string, any>

---@class CoreProgressProps : InterfaceProgressProps
---@field onFinish? fun()
---@field onCancel? fun()

---The table `GetCoreObject()` returns. `Players`, `Commands` and `Player` exist on the server only; `PlayerData` on the client only.
---@class Core
---@field Functions Functions
---@field Shared Shared
---@field Players table<integer, CorePlayer>
---@field PlayersByCid table<string, CorePlayer>
---@field PlayersByLicense table<string, CorePlayer>
---@field PlayersByPhone table<string, CorePlayer> online characters by `PlayerData.phone_number`
---@field Player PlayerModule
---@field Commands Commands
---@field Player_Buckets table<integer, { id: integer, bucket: integer }>
---@field Entity_Buckets table<integer, { id: integer, bucket: integer }>
---@field PlayerData PlayerData

---`Cobalt.Functions`, called with a dot. Each entry is tagged with the side it exists on.
---@class Functions
local Functions = {}

---**Client.**
---@return PlayerData
function Functions.GetPlayerData() end

---**Client.**
---@param cb fun(data: PlayerData)
function Functions.GetPlayerData(cb) end

---**Client.** The local character's full name.
---@return string
function Functions.GetName() end

---**Server.** A character's full name by server id or citizenid. Nil when no character matches.
---@param target integer|string
---@return string?
function Functions.GetName(target) end

---**Server.** Bans an online player by the chosen identifiers.
---@param playerId integer
---@param options BanOptions
---@return integer?
function Functions.Ban(playerId, options) end

---**Server.** Lifts bans matching a ban id or identifier.
---@param term string
---@param expiresBefore? integer
---@return integer
function Functions.Unban(term, expiresBefore) end

---**Client.**
---@return boolean
function Functions.IsWearingGloves() end

---**Client.**
---@return integer[]
function Functions.GetVehicles() end

---**Client.**
---@return integer[]
function Functions.GetObjects() end

---**Client.** Active player indices.
---@return integer[]
function Functions.GetPlayers() end

---**Server.** Server ids of loaded players.
---@return integer[]
function Functions.GetPlayers() end

---**Client.**
---@param ignoreList? integer[]
---@return integer[]
function Functions.GetPeds(ignoreList) end

---**Server.** Spawns a vehicle with `CreateVehicleServerSetter`, so no player needs to be near the coords. It gets a random plate and full fuel.
---@param source integer
---@param model integer|string
---@param coords? vector3|vector4 defaults to the player's position
---@param warp? boolean seat the player as the driver; the vehicle is deleted when that fails within 5 seconds
---@param vehicleType? string setter type such as `automobile`; looked up with `GetVehicleType` when left out
---@return integer? vehicle
---@return string? plate
function Functions.SpawnVehicle(source, model, coords, warp, vehicleType) end

---**Client.**
---@param vehicle integer
---@return string?
function Functions.GetPlate(vehicle) end

---**Client.**
---@param vehicle integer
---@return string?
function Functions.GetVehicleLabel(vehicle) end

---**Client.** Draws 2D text for one frame.
---@param x number
---@param y number
---@param width number
---@param height number
---@param scale number
---@param r integer
---@param g integer
---@param b integer
---@param a integer
---@param text string
function Functions.DrawText(x, y, width, height, scale, r, g, b, a, text) end

---**Client.** Draws world text for one frame.
---@param x number
---@param y number
---@param z number
---@param text string
function Functions.DrawText3D(x, y, z, text) end

---**Client.**
---@param coords vector3
---@return StreetName
function Functions.GetStreetNameAtCoords(coords) end

---**Client.**
---@param coords vector3
---@return string
function Functions.GetZoneAtCoords(coords) end

---**Client.**
---@param entity integer
---@return integer materialHash
---@return integer entityHit
---@return vector3 surfaceNormal
---@return vector3 endCoords
---@return boolean success
---@return integer retval
function Functions.GetGroundHash(entity) end

---**Client.** Shows a notification through cobalt_interfaces.
---@param text string|InterfaceNotifyProps
---@param notifyType? NotifyType
---@param length? integer milliseconds
---@param icon? string
function Functions.Notify(text, notifyType, length, icon) end

---**Server.** Shows a notification to one player, or every player with -1.
---@param source integer
---@param data string|InterfaceNotifyProps
---@param notifyType? NotifyType
---@param length? integer milliseconds
function Functions.Notify(source, data, notifyType, length) end

---**Client.** Yields and returns true when the bar fills.
---@param data CoreProgressProps
---@return boolean
function Functions.Progressbar(data) end

---**Client.** Positional form: returns at once, then calls `onFinish` or `onCancel`.
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
function Functions.Progressbar(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel) end

---**Client.**
---@param text string
---@param options? InterfaceTextUIOptions
function Functions.ShowTextUI(text, options) end

---**Client.**
function Functions.HideTextUI() end

---**Client.**
---@return boolean open
---@return string? text
function Functions.IsTextUIOpen() end

---**Client.** Yields until the check ends.
---@param difficulty SkillCheckDifficulity|SkillCheckDifficulity[]
---@param inputs? string[]
---@return boolean?
function Functions.SkillCheck(difficulty, inputs) end

---**Client.**
---@param context ContextMenu|ContextMenu[]
function Functions.RegisterContext(context) end

---**Client.**
---@param id string
function Functions.ShowContext(id) end

---**Client.**
---@param onExit? boolean runs the menu's onExit
function Functions.HideContext(onExit) end

---**Client.** Yields until the dialog closes.
---@param heading string
---@param rows (string|InputRow)[]
---@param options? InputOptions
---@return any[]?
function Functions.InputDialog(heading, rows, options) end

---**Client.** Yields until the dialog closes.
---@param data AlertProps
---@param timeout? integer milliseconds
---@return 'confirm'|'cancel'|nil
function Functions.AlertDialog(data, timeout) end

---**Client.**
---@param items InterfaceRadialItem|InterfaceRadialItem[]
function Functions.AddRadialItem(items) end

---**Client.**
---@param id string
function Functions.RemoveRadialItem(id) end

---**Client.**
---@param menu RadialMenu
function Functions.RegisterRadial(menu) end

---**Client.**
function Functions.HideRadial() end

---**Client.**
---@param state boolean
function Functions.DisableRadial(state) end

---**Server.**
---@param source integer
---@param idtype? 'license'|'license2'|'discord'|'steam'|'fivem'|'xbl'|'live'|'ip'|string
---@return string?
function Functions.GetIdentifier(source, idtype) end

---**Server.** The loaded player holding an identifier, or 0.
---@param identifier string
---@return integer
function Functions.GetSource(identifier) end

---**Server.** Looks up by server id, or by identifier when given a non-numeric string.
---@param source? integer|string
---@return CorePlayer?
function Functions.GetPlayer(source) end

---**Server.** Returns the character with this citizenid, online from memory or else loaded from `players` and cached for a minute. A player loaded from the database has `Offline = true` and no `PlayerData.source`.
---@param citizenid string
---@param onlineOnly? boolean look at online players only, never the database
---@return CorePlayer?
function Functions.GetPlayerByCitizenId(citizenid, onlineOnly) end

---**Server.** Returns the character on this Rockstar license, online from memory or else the license's character whose row changed last (`players.last_updated`, normally the last one played), loaded and cached for a minute. A player loaded from the database has `Offline = true` and no `PlayerData.source`.
---@param license string
---@param onlineOnly? boolean look at online players only, never the database
---@return CorePlayer?
function Functions.GetPlayerByLicense(license, onlineOnly) end

---**Server.** Returns the character whose npwd number in `players.phone_number` is `number`, online from memory or else loaded and cached for a minute. A player loaded from the database has `Offline = true` and no `PlayerData.source`.
---@param number string
---@param onlineOnly? boolean look at online players only, never the database
---@return CorePlayer?
function Functions.GetPlayerByPhone(number, onlineOnly) end

---**Server.** Returns the first online character whose `charinfo[property]` equals `value`, such as `firstname`, or else the first matching row, cached for a minute. Charinfo values such as names repeat, so the database match is whichever row MariaDB reads first. A player loaded from the database has `Offline = true` and no `PlayerData.source`. Errors when the lookup reaches the database and `property` isn't an identifier.
---@param property string charinfo key: letters, digits and underscores, not starting with a digit
---@param value string|number
---@param onlineOnly? boolean look at online players only, never the database
---@return CorePlayer?
function Functions.GetPlayerByCharInfo(property, value, onlineOnly) end

---**Server.** Online players whose cobalt_management job (`PlayerData.job`) has this name or type, and their count.
---@param job string job name or type
---@param checkOnDuty? boolean only players on duty
---@return integer[] players
---@return integer count
function Functions.GetPlayersByJob(job, checkOnDuty) end

---**Server.**
---@return table<integer, { id: integer, bucket: integer }> players
---@return table<integer, { id: integer, bucket: integer }> entities
function Functions.GetBucketObjects() end

---**Server.**
---@param source integer
---@param bucket integer
---@return boolean
function Functions.SetPlayerBucket(source, bucket) end

---**Server.**
---@param entity integer
---@param bucket integer
---@return boolean
function Functions.SetEntityBucket(entity, bucket) end

---**Server.**
---@param bucket integer
---@return integer[]|false
function Functions.GetPlayersInBucket(bucket) end

---**Server.**
---@param bucket integer
---@return integer[]|false
function Functions.GetEntitiesInBucket(bucket) end

---**Server.**
---@param source integer
---@param reason string
---@param setKickReason? fun(reason: string)
---@param deferrals? table
function Functions.Kick(source, reason, setKickReason, deferrals) end

---**Server.**
---@param source integer
---@return boolean
function Functions.IsWhitelisted(source) end

---**Server.**
---@param source integer
---@param permission string
function Functions.AddPermission(source, permission) end

---**Server.**
---@param source integer
---@param permission string
function Functions.RemovePermission(source, permission) end

---**Server.**
---@param source integer
---@param permission string|string[]
---@return boolean
function Functions.HasPermission(source, permission) end

---**Server.**
---@param source integer
---@return table<string, boolean>
function Functions.GetPermission(source) end

---**Server.**
---@param source integer
---@return boolean
function Functions.IsOptin(source) end

---**Server.**
---@param source integer
function Functions.ToggleOptin(source) end

---**Server.**
---@param source integer
---@return boolean banned
---@return string? message
function Functions.IsPlayerBanned(source) end

---**Server.**
---@param license string
---@return boolean
function Functions.IsLicenseInUse(license) end

---**Server.** Adds a method to every player object.
---@param methodName string
---@param handler fun(self: CorePlayer, ...): ...
---@return boolean ok
---@return string message
function Functions.SetMethod(methodName, handler) end

---**Server.** Adds a field to the core object.
---@param fieldName string
---@param data any
---@return boolean ok
---@return string message
function Functions.SetField(fieldName, data) end

---**Server.**
---@param jobName string
---@param job CoreJobDefinition
---@return boolean ok
---@return OrgResult message
function Functions.AddJob(jobName, job) end

---**Server.**
---@param jobs table<string, CoreJobDefinition>
---@return boolean ok
---@return string message
function Functions.AddJobs(jobs) end

---**Server.**
---@param jobName string
---@return boolean ok
---@return OrgResult message
function Functions.RemoveJob(jobName) end

---**Server.**
---@param jobName string
---@param job CoreJobDefinition
---@return boolean ok
---@return OrgResult message
function Functions.UpdateJob(jobName, job) end

---**Server.**
---@param gangName string
---@param gang GangDefinition
---@return boolean ok
---@return OrgResult message
function Functions.AddGang(gangName, gang) end

---**Server.**
---@param gangs table<string, GangDefinition>
---@return boolean ok
---@return string message
function Functions.AddGangs(gangs) end

---**Server.**
---@param gangName string
---@return boolean ok
---@return OrgResult message
function Functions.RemoveGang(gangName) end

---**Server.**
---@param gangName string
---@param gang GangDefinition
---@return boolean ok
---@return OrgResult message
function Functions.UpdateGang(gangName, gang) end

---**Server.**
---@return string
function Functions.GetCoreVersion() end

---**Server.** Adds a method to one player, a list of players, or every player with -1.
---@param ids integer|integer[]
---@param methodName string
---@param handler fun(self: CorePlayer, ...): ...
function Functions.AddPlayerMethod(ids, methodName, handler) end

---**Server.** Adds a field to one player, a list of players, or every player with -1.
---@param ids integer|integer[]
---@param fieldName string
---@param data any
function Functions.AddPlayerField(ids, fieldName, data) end
