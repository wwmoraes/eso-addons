--- @class StatusManagerStatuses
--- @field options string[]
--- @field values number[]

--- @class StatusManager : AddOnManifest
--- current player status
--- @field private current number
--- previous player status
--- @field private previous number
--- UI top level control
--- @field private control Control
--- account and character settings
--- @field public preferences Preferences
--- @field statuses StatusManagerStatuses
--- @field ignorableStatuses StatusManagerStatuses
--- @field ignorablePreviousStatuses StatusManagerStatuses
StatusManager = {
  current = nil,
  previous = nil,
  control = nil,
  statuses = {
    options = {},
    values = {},
  },
  ignorableStatuses = {
    options = {},
    values = {},
  },
  ignorablePreviousStatuses = {
    options = {},
    values = {},
  },
}

--- pseudo-status to change to the previous known ESO status
local CUSTOM_PLAYER_STATUS_PREVIOUS = -1
--- pseudo-status to skip a status change on an event
local CUSTOM_PLAYER_STATUS_IGNORE = 0

local LAM = LibAddonMenu2

--- @vararg string
function StatusManager:d(...)
  df("[%s] %s", self.name, table.concat({...}, " "))
end

--- @param formatter string
--- @vararg string
function StatusManager:df(formatter, ...)
  df("[%s] " .. formatter, self.name, table.concat({...}, " "))
end

function StatusManager:SetupPreferences()
  self.preferences = LibPreferences.New(self.savedVariables[1], {
    keepOffline = true,
    characterEnabled = true,
    onLoginStatus = CUSTOM_PLAYER_STATUS_IGNORE,
    onLogoutStatus = CUSTOM_PLAYER_STATUS_IGNORE,
    onQuitStatus = PLAYER_STATUS_OFFLINE,
    dungeonEnabled = true,
    dungeonOnEnterStatus = PLAYER_STATUS_DO_NOT_DISTURB,
    dungeonOnExitStatus = CUSTOM_PLAYER_STATUS_PREVIOUS,
    gameClientEnabled = true,
    gameClientOnBlur = PLAYER_STATUS_AWAY,
    gameClientOnFocus = CUSTOM_PLAYER_STATUS_PREVIOUS,
  }, {
    version = 1,
  })
end

function StatusManager:SetupAddOnMenu()
  --- @type LAM2Panel
  local panelData = {
    type = "panel",
    name = self.title,
    author = self.title,
    version = self.version,
    registerForRefresh = true,
    registerForDefaults = true,
  }

  --- @type table<number, LAM2OptionControl[]>
  local optionsTable = {
    --- @type LAM2CheckboxControl
    [1] = {
      type = "checkbox",
      name = "Global Settings",
      tooltip = "Share configuration across all characters",
      requiresReload = true,
      getFunc = self.preferences:AccountWideGetter(),
      setFunc = self.preferences:AccountWideSetter(),
    },
    --- @type LAM2CheckboxControl
    [2] = {
      type = "checkbox",
      name = "Keep Offline",
      tooltip = "Prevent changing your status if you're Offline",
      warning = "This option overrides all other mechanisms, and will keep you offline even if an event would change your status. You can restore their functionality by switching from Offline manually.",
      getFunc = self.preferences:Getter("keepOffline"),
      setFunc = self.preferences:Setter("keepOffline"),
    },
    --- @type LAM2SubmenuControl
    [3] = {
      type = "submenu",
      name = "Character",
      controls = {
        --- @type LAM2CheckboxControl
        [1] = {
          type = "checkbox",
          name = "Enabled",
          tooltip = "Monitor character changes",
          width = "full",
          requiresReload = true,
          getFunc = self.preferences:Getter("characterEnabled"),
          setFunc = self.preferences:Setter("characterEnabled"),
        },
        --- @type LAM2DropdownControl
        [2] = {
          type = "dropdown",
          name = "On login",
          choices = self.ignorableStatuses.options,
          choicesValues = self.ignorableStatuses.values,
          getFunc = self.preferences:Getter("onLoginStatus"),
          setFunc = self.preferences:Setter("onLoginStatus"),
          disabled = self.preferences:IsEqualGetter("characterEnabled", false),
          -- warning = "Only works when you logout from a logged in character. Your status won't change when you logout from anywhere else (e.g. character selection screen or login screen).",
        },
        --- @type LAM2DropdownControl
        [3] = {
          type = "dropdown",
          name = "On logout",
          choices = self.ignorableStatuses.options,
          choicesValues = self.ignorableStatuses.values,
          getFunc = self.preferences:Getter("onLogoutStatus"),
          setFunc = self.preferences:Setter("onLogoutStatus"),
          disabled = self.preferences:IsEqualGetter("characterEnabled", false),
        },
        --- @type LAM2DropdownControl
        [4] = {
          type = "dropdown",
          name = "On quit",
          choices = self.ignorableStatuses.options,
          choicesValues = self.ignorableStatuses.values,
          getFunc = self.preferences:Getter("onQuitStatus"),
          setFunc = self.preferences:Setter("onQuitStatus"),
          disabled = self.preferences:IsEqualGetter("characterEnabled", false),
        },
      },
    },
    --- @type LAM2SubmenuControl
    [4] = {
      type = "submenu",
      name = "Dungeon",
      controls = {
        --- @type LAM2CheckboxControl
        [1] = {
          type = "checkbox",
          name = "Enabled",
          tooltip = "Monitor area changes",
          width = "full",
          requiresReload = true,
          getFunc = self.preferences:Getter("dungeonEnabled"),
          setFunc = self.preferences:Setter("dungeonEnabled"),
        },
        --- @type LAM2DropdownControl
        [2] = {
          type = "dropdown",
          name = "On enter",
          width = "half",
          choices = self.ignorableStatuses.options,
          choicesValues = self.ignorableStatuses.values,
          getFunc = self.preferences:Getter("dungeonOnEnterStatus"),
          setFunc = self.preferences:Setter("dungeonOnEnterStatus"),
          disabled = self.preferences:IsEqualGetter("dungeonEnabled", false),
        },
        --- @type LAM2DropdownControl
        [3] = {
          type = "dropdown",
          name = "On exit",
          width = "half",
          choices = self.ignorablePreviousStatuses.options,
          choicesValues = self.ignorablePreviousStatuses.values,
          getFunc = self.preferences:Getter("dungeonOnExitStatus"),
          setFunc = self.preferences:Setter("dungeonOnExitStatus"),
          disabled = self.preferences:IsEqualGetter("dungeonEnabled", false),
        },
      },
    },
    --- @type LAM2SubmenuControl
    [5] = {
      type = "submenu",
      name = "Game Client",
      controls = {
        --- @type LAM2CheckboxControl
        [1] = {
          type = "checkbox",
          name = "Enabled",
          tooltip = "Monitor game client focus changes",
          width = "full",
          requiresReload = true,
          getFunc = self.preferences:Getter("gameClientEnabled"),
          setFunc = self.preferences:Setter("gameClientEnabled"),
        },
        --- @type LAM2DropdownControl
        [2] = {
          type = "dropdown",
          name = "On blur",
          width = "half",
          choices = self.ignorableStatuses.options,
          choicesValues = self.ignorableStatuses.values,
          getFunc = self.preferences:Getter("gameClientOnBlur"),
          setFunc = self.preferences:Setter("gameClientOnBlur"),
          disabled = self.preferences:IsEqualGetter("gameClientEnabled", false),
        },
        --- @type LAM2DropdownControl
        [3] = {
          type = "dropdown",
          name = "On focus",
          width = "half",
          choices = self.ignorablePreviousStatuses.options,
          choicesValues = self.ignorablePreviousStatuses.values,
          getFunc = self.preferences:Getter("gameClientOnFocus"),
          setFunc = self.preferences:Setter("gameClientOnFocus"),
          disabled = self.preferences:IsEqualGetter("gameClientEnabled", false),
        },
      }
    },
  }

  LAM:RegisterAddonPanel(self.name, panelData)
  LAM:RegisterOptionControls(self.name, optionsTable)
end

function StatusManager:SetupSlashCommands()
  SLASH_COMMANDS["/online"] = function()
    SelectPlayerStatus(PLAYER_STATUS_ONLINE)
  end
  SLASH_COMMANDS["/dnd"] = function()
    SelectPlayerStatus(PLAYER_STATUS_DO_NOT_DISTURB)
  end
  SLASH_COMMANDS["/away"] = function()
    SelectPlayerStatus(PLAYER_STATUS_AWAY)
  end
  SLASH_COMMANDS["/offline"] = function()
    SelectPlayerStatus(PLAYER_STATUS_OFFLINE)
  end
end

function StatusManager:SetupStatuses()
  table.insert(self.ignorableStatuses.options, "Ignore")
  table.insert(self.ignorableStatuses.values, CUSTOM_PLAYER_STATUS_IGNORE)
  table.insert(self.ignorablePreviousStatuses.options, "Ignore")
  table.insert(self.ignorablePreviousStatuses.values, CUSTOM_PLAYER_STATUS_IGNORE)
  table.insert(self.ignorablePreviousStatuses.options, "Previous")
  table.insert(self.ignorablePreviousStatuses.values, CUSTOM_PLAYER_STATUS_PREVIOUS)

  for status = 1, GetNumPlayerStatuses() do
    local texture = GetPlayerStatusIcon(status)
    local name = GetString("SI_PLAYERSTATUS", status)
    local entryText = zo_iconTextFormat(texture, 32, 32, name)
    table.insert(self.statuses.options, entryText)
    table.insert(self.statuses.values, status)
    table.insert(self.ignorableStatuses.options, entryText)
    table.insert(self.ignorableStatuses.values, status)
    table.insert(self.ignorablePreviousStatuses.options, entryText)
    table.insert(self.ignorablePreviousStatuses.values, status)
  end
end

--- @param status number
function StatusManager:SetNextStatus(status)
  if status == CUSTOM_PLAYER_STATUS_IGNORE then
    return
  end

  --- @type number
  local nextStatus = self:GetCurrentStatus()
  if status == CUSTOM_PLAYER_STATUS_PREVIOUS then
    nextStatus = self:GetPreviousStatus()
  elseif status >= 1 and status <= #self.statuses then
    nextStatus = status
  else
    error("unknown status "..status)
  end

  SelectPlayerStatus(nextStatus)
end

--- @return number
function StatusManager:GetCurrentStatus()
  self.current = self.current or GetPlayerStatus()
  return self.current
end

--- @return number
function StatusManager:GetPreviousStatus()
  self.previous = self.previous or self:GetCurrentStatus()
  return self.previous
end

--- changes the status to offline on quit
--- @param eventId integer
--- @param deferMilliseconds integer
--- @param quitRequested boolean
local function OnLogoutDeferred(eventId, deferMilliseconds, quitRequested)
  if eventId ~= EVENT_LOGOUT_DEFERRED then
    return
  end

  -- don't change the status if we are currently offline
  if StatusManager.preferences.keepOffline and StatusManager:GetCurrentStatus() == PLAYER_STATUS_OFFLINE then
    StatusManager:df("Currently %s; skipping status change.", GetString("SI_PLAYERSTATUS", PLAYER_STATUS_OFFLINE))
    return
  end

  if not quitRequested then
    StatusManager:SetNextStatus(StatusManager.preferences.onLogoutStatus)
  else
    StatusManager:SetNextStatus(StatusManager.preferences.onQuitStatus)
  end
end

--- changes the player status based on their activity (dungeon/overland)
--- @param eventId number
--- @param initial boolean
local function OnPlayerActivated(eventId, initial)
  if eventId ~= EVENT_PLAYER_ACTIVATED then
    return
  end

  if initial == true then
    StatusManager:d("loaded.")
  end

  -- don't change the status if we are currently offline
  if StatusManager.preferences.keepOffline and StatusManager:GetCurrentStatus() == PLAYER_STATUS_OFFLINE then
    StatusManager:df("Currently %s; skipping status change.", GetString("SI_PLAYERSTATUS", PLAYER_STATUS_OFFLINE))
    return
  end

  -- set do not disturb when entering a dungeon/instance
  -- reverts to the previous status otherwise
  if IsUnitInDungeon("player") then
    StatusManager:SetNextStatus(StatusManager.preferences.dungeonOnEnterStatus)
  else
    StatusManager:SetNextStatus(StatusManager.preferences.dungeonOnExitStatus)
  end
end

--- @param eventId number
--- @param hasFocus boolean
local function OnGameFocusChanged(eventId, hasFocus)
  if eventId ~= EVENT_GAME_FOCUS_CHANGED then
    return
  end

  -- don't change the status if we are currently offline
  if StatusManager.preferences.keepOffline and StatusManager:GetCurrentStatus() == PLAYER_STATUS_OFFLINE then
    StatusManager:df("Currently %s; skipping status change.", GetString("SI_PLAYERSTATUS", PLAYER_STATUS_OFFLINE))
    return
  end

  if hasFocus then
    StatusManager:SetNextStatus(StatusManager.preferences.gameClientOnFocus)
  else
    StatusManager:SetNextStatus(StatusManager.preferences.gameClientOnBlur)
  end
end

--- @param eventId integer
--- @param oldStatus integer
--- @param newStatus integer
local function OnPlayerStatusChanged(eventId, oldStatus, newStatus)
  if eventId ~= EVENT_PLAYER_STATUS_CHANGED then
    return
  end
  if oldStatus == newStatus then
    return
  end

  StatusManager.current = newStatus
  StatusManager.previous = oldStatus
  StatusManager:UIUpdateStatus()
end

--- @param eventId number
--- @param addonName string
local function OnAddOnLoaded(eventId, addonName)
  if eventId ~= EVENT_ADD_ON_LOADED then
    return
  end
  if addonName ~= StatusManager.name then
    return
  end
  EVENT_MANAGER:UnregisterForEvent(StatusManager.name, EVENT_ADD_ON_LOADED)

  StatusManager:SetupPreferences()
  StatusManager:SetupAddOnMenu()
  StatusManager:SetupSlashCommands()

  EVENT_MANAGER:RegisterForEvent(StatusManager.name, EVENT_PLAYER_STATUS_CHANGED, OnPlayerStatusChanged)

  if StatusManager.preferences.characterEnabled == true then
    EVENT_MANAGER:RegisterForEvent(StatusManager.name, EVENT_LOGOUT_DEFERRED, OnLogoutDeferred)
  end

  if StatusManager.preferences.dungeonEnabled == true then
    EVENT_MANAGER:RegisterForEvent(StatusManager.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
  end

  if StatusManager.preferences.gameClientEnabled == true then
    EVENT_MANAGER:RegisterForEvent(StatusManager.name, EVENT_GAME_FOCUS_CHANGED, OnGameFocusChanged)
  end
end

EVENT_MANAGER:RegisterForEvent(StatusManager.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
