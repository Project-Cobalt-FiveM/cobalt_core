---@meta

---`exports.cobalt_core`. Each export is tagged with the side it exists on.
---@class CobaltCoreExports
local CobaltCoreExports = {}

---**Client.** The core object, or only the listed keys of it.
---@param filters? string[]
---@return Core
function CobaltCoreExports:GetCoreObject(filters) end

---**Server.** The core object, or only the listed keys of it.
---@param filters? string[]
---@return Core
function CobaltCoreExports:GetCoreObject(filters) end

---**Shared.** A `Cobalt.Shared` table, such as `GetShared('Jobs')`, or one entry of it, such as `GetShared('Jobs', 'police')`.
---@param namespace 'Vehicles'|'VehicleHashes'|'Gangs'|'Jobs'|'Locations'
---@param item? string|integer
---@return any
function CobaltCoreExports:GetShared(namespace, item) end

---**Client.** Whether a progress bar is running.
---@return boolean
function CobaltCoreExports:progressActive() end

---**Client.** Cancels the running progress bar, as if the player pressed cancel.
function CobaltCoreExports:cancelProgress() end

---**Server.** Bans the player for an exploit and drops them.
---@param playerId integer
---@param origin string ban reason
function CobaltCoreExports:ExploitBan(playerId, origin) end

---**Server.** Bans an online player by the chosen identifiers, which `IsPlayerBanned` then matches on connect. Doesn't drop them.
---@param playerId integer
---@param options BanOptions
---@return integer? banId nil when the player has none of the chosen identifiers
function CobaltCoreExports:Ban(playerId, options) end

---**Server.** Lifts bans matching a ban id or a license, Discord or Steam identifier.
---@param term string
---@param expiresBefore? integer lifts only bans that end before this unix time. Pass the permanent-ban time to leave permanent bans in place
---@return integer removed
function CobaltCoreExports:Unban(term, expiresBefore) end

---**Server.** Sets hunger or thirst, clamped to 0 to 100, and updates the HUD.
---@param source integer
---@param need 'hunger'|'thirst'
---@param value number
---@return boolean set false when the need is unknown, the value isn't a number or the player isn't loaded
function CobaltCoreExports:SetNeed(source, need, value) end

---**Server.** Adds to hunger or thirst, clamped to 0 to 100, and updates the HUD.
---@param source integer
---@param need 'hunger'|'thirst'
---@param amount number negative to lower
---@return boolean added false when the need is unknown, the amount isn't a number or the player isn't loaded
function CobaltCoreExports:AddNeed(source, need, amount) end

---**Server.** The citizenid owning a plate, and that vehicle's `player_vehicles` id.
---@param plate string
---@return string? citizenid
---@return integer? vehicleId
function CobaltCoreExports:GetVehicleOwnerByPlate(plate) end

---**Server.** A random eight-character plate that no `player_vehicles` row uses. Errors when ten tries all hit taken plates.
---@return string
function CobaltCoreExports:GeneratePlate() end

---**Server.** Rows of `player_vehicles` owned by a character, without the `trunk` and `glovebox` inventory columns. Pass `fields` to select only those columns; an unknown or inventory column raises an error.
---@param citizenid string
---@param fields? string[] column names, such as `{ 'plate' }`; every column but `trunk` and `glovebox` when left out
---@return table[]
function CobaltCoreExports:GetVehiclesByCitizenId(citizenid, fields) end

---**Server.** The `CreateVehicleServerSetter` type of a model (`automobile`, `bike`, `boat`, `heli`, `plane`, `submarine`, `train`), read from the shared vehicle list, or asked of `source`'s client for models not in it. Nil when the model is unknown or the client doesn't answer.
---@param source integer
---@param model string
---@return string?
function CobaltCoreExports:GetVehicleType(source, model) end

---**Client.** The local character's player data: citizenid, charinfo, job, gang, money and metadata.
---@return PlayerData
function CobaltCoreExports:GetPlayerData() end

---**Client.** The local character's player data: citizenid, charinfo, job, gang, money and metadata.
---@param cb fun(data: PlayerData)
function CobaltCoreExports:GetPlayerData(cb) end

---**Client.** The local character's full name.
---@return string
function CobaltCoreExports:GetName() end

---**Server.** A character's full name by server id or citizenid, read from memory when online and from `players` when not. Nil when no character matches or it has no name.
---@param target integer|string server id or citizenid
---@return string?
function CobaltCoreExports:GetName(target) end

---**Client.** Whether the local ped's arms drawable counts as gloves, which keeps fingerprints off evidence.
---@return boolean
function CobaltCoreExports:IsWearingGloves() end

---**Client.** Every vehicle the client has loaded.
---@return integer[]
function CobaltCoreExports:GetVehicles() end

---**Client.** Every object the client has loaded.
---@return integer[]
function CobaltCoreExports:GetObjects() end

---**Client.** Active player indices.
---@return integer[]
function CobaltCoreExports:GetPlayers() end

---**Server.** Server ids of loaded players.
---@return integer[]
function CobaltCoreExports:GetPlayers() end

---**Client.** Every ped the client has loaded, except the ones listed in `ignoreList`.
---@param ignoreList? integer[]
---@return integer[]
function CobaltCoreExports:GetPeds(ignoreList) end

---**Server.** Spawns a vehicle with `CreateVehicleServerSetter`, so no player needs to be near the coords. It gets a random plate and full fuel.
---@param source integer
---@param model integer|string
---@param coords? vector3|vector4 defaults to the player's position
---@param warp? boolean seat the player as the driver; the vehicle is deleted when that fails within 5 seconds
---@param vehicleType? string setter type such as `automobile`; looked up with `GetVehicleType` when left out
---@return integer? vehicle
---@return string? plate
function CobaltCoreExports:SpawnVehicle(source, model, coords, warp, vehicleType) end

---**Client.** The vehicle's plate with surrounding spaces trimmed. Nil for no vehicle.
---@param vehicle integer
---@return string?
function CobaltCoreExports:GetPlate(vehicle) end

---**Client.** The vehicle's display name from the game's text labels, such as `Sultan`. Nil for no vehicle.
---@param vehicle integer
---@return string?
function CobaltCoreExports:GetVehicleLabel(vehicle) end

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
function CobaltCoreExports:DrawText(x, y, width, height, scale, r, g, b, a, text) end

---**Client.** Draws world text for one frame.
---@param x number
---@param y number
---@param z number
---@param text string
function CobaltCoreExports:DrawText3D(x, y, z, text) end

---**Client.** The street and cross street at a position.
---@param coords vector3
---@return StreetName
function CobaltCoreExports:GetStreetNameAtCoords(coords) end

---**Client.** The display name of the map zone at a position, such as `Legion Square`.
---@param coords vector3
---@return string
function CobaltCoreExports:GetZoneAtCoords(coords) end

---**Client.** Casts a capsule down through the entity and returns the material it lands on, with the raw shape test results.
---@param entity integer
---@return integer materialHash
---@return integer entityHit
---@return vector3 surfaceNormal
---@return vector3 endCoords
---@return boolean success
---@return integer retval
function CobaltCoreExports:GetGroundHash(entity) end

---**Client.** Fades out, freezes the player (and their vehicle) while the area streams in, then moves them. With no `z` it lands them on the ground under x, y, or on water; when neither turns up within 5 seconds it leaves them 150 meters up and notifies. Yields.
---@param x number
---@param y number
---@param z? number
---@param heading? number
---@return boolean grounded false when `z` was nil and no ground was found
function CobaltCoreExports:Teleport(x, y, z, heading) end

---**Client.** Shows a notification through cobalt_interfaces.
---@param text string|InterfaceNotifyProps
---@param notifyType? NotifyType
---@param length? integer milliseconds
---@param icon? string
function CobaltCoreExports:Notify(text, notifyType, length, icon) end

---**Server.** Shows a notification to one player, or every player with -1.
---@param source integer
---@param data string|InterfaceNotifyProps
---@param notifyType? NotifyType
---@param length? integer milliseconds
function CobaltCoreExports:Notify(source, data, notifyType, length) end

---**Client.** Yields and returns true when the bar fills.
---@param data CoreProgressProps
---@return boolean
function CobaltCoreExports:Progressbar(data) end

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
function CobaltCoreExports:Progressbar(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel) end

---**Client.** Shows the text prompt, such as `[E] Open trunk`, until `HideTextUI`.
---@param text string
---@param options? InterfaceTextUIOptions
function CobaltCoreExports:ShowTextUI(text, options) end

---**Client.** Hides the prompt only when the calling resource showed it.
function CobaltCoreExports:HideTextUI() end

---**Client.** Whether the text prompt is showing, and its text.
---@return boolean open
---@return string? text
function CobaltCoreExports:IsTextUIOpen() end

---**Client.** Yields until the check ends; false at once, with a notification, while another check runs.
---@param difficulty SkillCheckDifficulity|SkillCheckDifficulity[]
---@param inputs? string[]
---@return boolean?
function CobaltCoreExports:SkillCheck(difficulty, inputs) end

---**Client.** Registers one or more context menus by id, for `ShowContext`.
---@param context ContextMenu|ContextMenu[]
function CobaltCoreExports:RegisterContext(context) end

---**Client.** Opens a context menu registered with `RegisterContext`.
---@param id string
function CobaltCoreExports:ShowContext(id) end

---**Client.** Closes the open context menu.
---@param onExit? boolean runs the menu's onExit
function CobaltCoreExports:HideContext(onExit) end

---**Client.** Yields until the dialog closes; nil at once, with a notification, while another is open.
---@param heading string
---@param rows (string|InputRow)[]
---@param options? InputOptions
---@return any[]?
function CobaltCoreExports:InputDialog(heading, rows, options) end

---**Client.** Yields until the dialog closes; 'cancel' at once, with a notification, while another is open.
---@param data AlertProps
---@param timeout? integer milliseconds
---@return 'confirm'|'cancel'|nil
function CobaltCoreExports:AlertDialog(data, timeout) end

---**Client.** Adds items to the radial menu.
---@param items InterfaceRadialItem|InterfaceRadialItem[]
function CobaltCoreExports:AddRadialItem(items) end

---**Client.** Removes a radial menu item by id.
---@param id string
function CobaltCoreExports:RemoveRadialItem(id) end

---**Client.** Registers a radial submenu that items open through their `menu` field.
---@param menu RadialMenu
function CobaltCoreExports:RegisterRadial(menu) end

---**Client.** Closes the radial menu.
function CobaltCoreExports:HideRadial() end

---**Client.** Stops the radial menu from opening while `state` is true.
---@param state boolean
function CobaltCoreExports:DisableRadial(state) end

---**Server.** Gives the player a runtime-only job beside their real one, replacing any temp job they hold. Never saved; cleared on logout and when the calling resource stops. Mirrored to the `cobalt:tempjob` and `cobalt:tempjob:label` state bags.
---@param src integer
---@param name string
---@param data? { label?: string } | table
---@return boolean
function CobaltCoreExports:SetTempJob(src, name, data) end

---**Server.** Ends the player's temporary job.
---@param src integer
---@return boolean cleared false when the player held no temp job
function CobaltCoreExports:ClearTempJob(src) end

---**Server.** The player's temp job, or nil when they have none.
---@param src integer
---@return TempJob?
function CobaltCoreExports:GetTempJob(src) end

---**Client.** The licence types from `licenses` in `config/shared.lua`, by key. The ID card is not one.
---@return table<string, LicenseType>
function CobaltCoreExports:GetLicenseTypes() end

---**Server.** The licence types from `licenses` in `config/shared.lua`, by key. The ID card is not one.
---@return table<string, LicenseType>
function CobaltCoreExports:GetLicenseTypes() end

---**Server.** False for an unknown type or character.
---@param target integer|string server id or citizenid
---@param key string
---@return boolean
function CobaltCoreExports:HasLicense(target, key) end

---**Server.** Every licence type's record for the character: whether it is held, who granted it and when, when it was revoked, and its points. Nil when the character doesn't exist.
---@param target integer|string server id or citizenid
---@return table<string, LicenseRecord>?
function CobaltCoreExports:GetLicenseRecords(target) end

---**Server.** The metadata for a new ID or licence card item, from the player's loaded character and dated today. Nil when the player has no character loaded.
---@param source integer
---@param key? string the licence key for a licence card, such as `driver` or `weapon`; omit it for an ID card
---@return CardItemMetadata?
function CobaltCoreExports:CardMetadata(source, key) end

---**Server.** The `id_card`, `driver_license` and `weapon_license` items' server export. On `usedItem` it shows the card to its holder and, when `idCard.showNearby` is set, to every player within `idCard.nearbyDistance` meters in the holder's routing bucket.
---@param event 'usingItem' | 'usedItem'
---@param item { name: string }
---@param inventory { id: string, source: integer }
---@param slot { id: string }
function CobaltCoreExports:UseCard(event, item, inventory, slot) end

---**Server.** Grants a licence, records when and by whom in `metadata.licenceGrants`, clears its revocation and points, saves an offline character, and fires `cobalt_core:server:licenseChanged(citizenid, key, true, source?)`. False when the type is unknown, the character doesn't exist or already holds it.
---@param target integer|string server id or citizenid
---@param key string
---@param issuer? string shown on City Hall's card counter, such as `LSPD` or `the DMV`
---@return boolean changed
function CobaltCoreExports:GrantLicense(target, key, issuer) end

---**Server.** Revokes a licence and records when in `metadata.licenceRevoked`, saving an offline character, and fires `cobalt_core:server:licenseChanged(citizenid, key, false, source?)`. False when the type is unknown, the character doesn't exist or doesn't hold it.
---@param target integer|string server id or citizenid
---@param key string
---@return boolean changed
function CobaltCoreExports:RevokeLicense(target, key) end

---**Server.** Adds points to a held licence whose type has a `pointsLimit`, and revokes it once the total reaches that limit, firing `licenseChanged`. Returns nil and false when the type has no limit, the amount isn't positive, or the character doesn't hold it.
---@param target integer|string server id or citizenid
---@param key string
---@param amount integer
---@return integer? total
---@return boolean revoked
function CobaltCoreExports:AddLicensePoints(target, key, amount) end

---**Server.** One of the player's identifiers, `license` by default.
---@param source integer
---@param idtype? 'license'|'license2'|'discord'|'steam'|'fivem'|'xbl'|'live'|'ip'|string
---@return string?
function CobaltCoreExports:GetIdentifier(source, idtype) end

---**Server.** The loaded player holding an identifier, or 0.
---@param identifier string
---@return integer
function CobaltCoreExports:GetSource(identifier) end

---**Server.** Looks up by server id, or by identifier when given a non-numeric string.
---@param source? integer|string
---@return CorePlayer?
function CobaltCoreExports:GetPlayer(source) end

---**Server.** The online player with that citizenid.
---@param citizenid string
---@return CorePlayer?
function CobaltCoreExports:GetPlayerByCitizenId(citizenid) end

---**Server.** Loads the character from the database when it is not online.
---@param citizenid string
---@return CorePlayer?
function CobaltCoreExports:GetOfflinePlayerByCitizenId(citizenid) end

---**Server.** One metadata key for each character, online ones from memory and the rest from `players` in one query. Characters that don't exist or lack the key are left out. Errors when `key` isn't an identifier.
---@param citizenids string[]
---@param key string letters, digits and underscores, not starting with a digit
---@return table<string, any> values by citizenid
function CobaltCoreExports:GetMetaData(citizenids, key) end

---**Server.** Sets one metadata key on a character and writes it to `players.metadata` straight away. A loaded character also gets it in memory and on its client, and `job` or `gang` also replace `PlayerData.job` or `PlayerData.gang`. False when no character has that citizenid. Errors when `key` isn't an identifier.
---@param citizenid string
---@param key string letters, digits and underscores, not starting with a digit
---@param value any JSON-encodable; nil clears it
---@return boolean written
function CobaltCoreExports:SetMetaData(citizenid, key, value) end

---**Server.** The online player with that Rockstar license.
---@param license string
---@return CorePlayer?
function CobaltCoreExports:GetPlayerByLicense(license) end

---**Server.** The online player whose character owns `number` in `players.phone_number`, the number npwd gives the phone.
---@param number string
---@return CorePlayer?
function CobaltCoreExports:GetPlayerByPhone(number) end

---**Server.** The online player whose `charinfo` field matches, such as `firstname`.
---@param property string charinfo key
---@param value string
---@return CorePlayer?
function CobaltCoreExports:GetPlayerByCharInfo(property, value) end

---**Server.** Online players whose cobalt_management job (`PlayerData.job`) has this name or type, and their count.
---@param job string job name or type
---@param checkOnDuty? boolean only players on duty
---@return integer[] players
---@return integer count
function CobaltCoreExports:GetPlayersByJob(job, checkOnDuty) end

---**Server.** The routing bucket of every player and entity that cobalt_core has moved out of bucket 0.
---@return table<integer, { id: integer, bucket: integer }> players
---@return table<integer, { id: integer, bucket: integer }> entities
function CobaltCoreExports:GetBucketObjects() end

---**Server.** Moves a player to a routing bucket.
---@param source integer
---@param bucket integer
---@return boolean
function CobaltCoreExports:SetPlayerBucket(source, bucket) end

---**Server.** Moves an entity to a routing bucket.
---@param entity integer
---@param bucket integer
---@return boolean
function CobaltCoreExports:SetEntityBucket(entity, bucket) end

---**Server.** The players in a routing bucket, or false when there are none.
---@param bucket integer
---@return integer[]|false
function CobaltCoreExports:GetPlayersInBucket(bucket) end

---**Server.** The entities in a routing bucket, or false when there are none.
---@param bucket integer
---@return integer[]|false
function CobaltCoreExports:GetEntitiesInBucket(bucket) end

---**Server.** Drops the player with a reason. During connection, pass `setKickReason` and `deferrals` from `playerConnecting`.
---@param source integer
---@param reason string
---@param setKickReason? fun(reason: string)
---@param deferrals? table
function CobaltCoreExports:Kick(source, reason, setKickReason, deferrals) end

---**Server.** Whether the player may join while the whitelist is on. Always true when it is off.
---@param source integer
---@return boolean
function CobaltCoreExports:IsWhitelisted(source) end

---**Server.** Gives the player a rank (`staff`, `admin` or `owner`) for this session.
---@param source integer
---@param permission string
function CobaltCoreExports:AddPermission(source, permission) end

---**Server.** Takes a rank from the player for this session.
---@param source integer
---@param permission string
function CobaltCoreExports:RemovePermission(source, permission) end

---**Server.** Whether the player holds the rank, or any of the ranks listed. Higher ranks pass too.
---@param source integer
---@param permission string|string[]
---@return boolean
function CobaltCoreExports:HasPermission(source, permission) end

---**Server.** Every rank the player holds.
---@param source integer
---@return table<string, boolean>
function CobaltCoreExports:GetPermission(source) end

---**Server.** Whether an admin has opted in to admin reports. False for non-admins.
---@param source integer
---@return boolean
function CobaltCoreExports:IsOptin(source) end

---**Server.** Flips an admin's opt-in to admin reports.
---@param source integer
function CobaltCoreExports:ToggleOptin(source) end

---**Server.** Whether a ban matches the player by license, Discord or Steam, with the kick message. Removes expired bans first.
---@param source integer
---@return boolean banned
---@return string? message
function CobaltCoreExports:IsPlayerBanned(source) end

---**Server.** Whether a connected player already has that Rockstar license.
---@param license string
---@return boolean
function CobaltCoreExports:IsLicenseInUse(license) end

---**Server.** Adds a method to every player object.
---@param methodName string
---@param handler fun(self: CorePlayer, ...): ...
---@return boolean ok
---@return string message
function CobaltCoreExports:SetMethod(methodName, handler) end

---**Server.** Adds a field to the core object.
---@param fieldName string
---@param data any
---@return boolean ok
---@return string message
function CobaltCoreExports:SetField(fieldName, data) end

---**Server.** Adds a job at runtime and sends it to every client.
---@param jobName string
---@param job CoreJobDefinition
---@return boolean ok
---@return OrgResult message
function CobaltCoreExports:AddJob(jobName, job) end

---**Server.** Adds several jobs at runtime.
---@param jobs table<string, CoreJobDefinition>
---@return boolean ok
---@return string message
function CobaltCoreExports:AddJobs(jobs) end

---**Server.** Removes a job at runtime.
---@param jobName string
---@return boolean ok
---@return OrgResult message
function CobaltCoreExports:RemoveJob(jobName) end

---**Server.** Replaces a job's definition at runtime.
---@param jobName string
---@param job CoreJobDefinition
---@return boolean ok
---@return OrgResult message
function CobaltCoreExports:UpdateJob(jobName, job) end

---**Server.** Adds a gang at runtime and sends it to every client.
---@param gangName string
---@param gang GangDefinition
---@return boolean ok
---@return OrgResult message
function CobaltCoreExports:AddGang(gangName, gang) end

---**Server.** Adds several gangs at runtime.
---@param gangs table<string, GangDefinition>
---@return boolean ok
---@return string message
function CobaltCoreExports:AddGangs(gangs) end

---**Server.** Removes a gang at runtime.
---@param gangName string
---@return boolean ok
---@return OrgResult message
function CobaltCoreExports:RemoveGang(gangName) end

---**Server.** Adds vehicles to `data/vehicles.lua` or changes fields on existing ones, then saves the file. A new vehicle needs `name`, `category`, `price` and `type`. Players who joined before the change see it after their next join.
---@param vehicles table<string, { name?: string, brand?: string, category?: string, price?: integer, type?: string, shops?: string[], image?: string, enabled?: boolean }> fields by model
---@return string[] changed the models added or updated, sorted
function CobaltCoreExports:SetVehicles(vehicles) end

---**Server.** Replaces a gang's definition at runtime.
---@param gangName string
---@param gang GangDefinition
---@return boolean ok
---@return OrgResult message
function CobaltCoreExports:UpdateGang(gangName, gang) end

---**Server.** cobalt_core's manifest version.
---@return string
function CobaltCoreExports:GetCoreVersion() end

---**Server.** Adds a method to one player, a list of players, or every player with -1.
---@param ids integer|integer[]
---@param methodName string
---@param handler fun(self: CorePlayer, ...): ...
function CobaltCoreExports:AddPlayerMethod(ids, methodName, handler) end

---**Server.** Adds a field to one player, a list of players, or every player with -1.
---@param ids integer|integer[]
---@param fieldName string
---@param data any
function CobaltCoreExports:AddPlayerField(ids, fieldName, data) end

---**Server.** Queues a log event for FiveMesh. `category` becomes the event type (`banking.deposit`), the calling resource fills `resource`, and `security` is sent as `warn` with a `security.` type prefix. Queued events go out in batches every 5 seconds and on stop. Returns false when FiveMesh is disabled or the arguments are invalid.
---@param category string
---@param message string up to 2048 characters
---@param data? table JSON object stored with the event
---@param level? LogLevel defaults to `info`
---@return boolean queued
function CobaltCoreExports:Log(category, message, data, level) end

---**Server.** `Log` with the player's server id, identifiers and citizenid attached, plus a target player's when given.
---@param source integer
---@param category string
---@param message string
---@param data? table
---@param level? LogLevel
---@param target? integer
---@return boolean queued
function CobaltCoreExports:LogPlayer(source, category, message, data, level, target) end

---**Server.** Uploads a Base64 file to the FiveMesh CDN and returns its public URL. Yields; retries 429 and 5xx.
---@param path string folder and file name, such as `uploads/phone/123.webp`
---@param data string standard Base64 or a `data:<type>;base64,` URL
---@param contentType? string such as `image/webp`
---@return string? url
---@return string? error
function CobaltCoreExports:UploadFile(path, data, contentType) end

exports.cobalt_core = CobaltCoreExports
