--- @param control Control
function StatusManager:UIOnInitialized(control)
  self.control = control

  --- @type Control
  local container = GetControl(self.control, "ComboBox")
  if container == nil then
    self:d("Combo box container not found.")
    return
  end

  --- @type ZO_ComboBox
  local comboBox = ZO_ComboBox_ObjectFromContainer(container)
  if comboBox == nil then
    self:d("Combo box not initialized.")
    return
  end

  comboBox:SetSortsItems(false)
  comboBox:SetDropdownFont("ZoFontHeader")
  comboBox:SetSpacing(8)

  for status = 1, GetNumPlayerStatuses() do
    local texture = GetPlayerStatusIcon(status)
    local name = GetString("SI_PLAYERSTATUS", status)
    local entryText = zo_iconTextFormat(texture, 32, 32, name)
    local entry = comboBox:CreateItemEntry(entryText, function(_, _, entry)
      SelectPlayerStatus(entry.status)
    end)
    entry.status = status
    comboBox:AddItem(entry)
  end

  if CHAT_SYSTEM.isMinimized then
    StatusManager:OnShowMinBar()
  else
    StatusManager:OnHideMinBar()
  end

  ZO_PreHook(CHAT_SYSTEM, "ShowMinBar", function() StatusManager:OnShowMinBar()end)
  ZO_PreHook(CHAT_SYSTEM, "HideMinBar", function() StatusManager:OnHideMinBar()end)

  StatusManager:UIUpdateStatus()
end

function StatusManager:UIUpdateStatus()
  if self.control == nil then
    self:df("top level control not found")
    return
  end

  --- @type ButtonControl
  local iconButton = GetControl(self.control, "ComboBoxIcon")
  if iconButton == nil then
    self:d("Combo box icon button not found.")
    return
  end

  iconButton:SetNormalTexture(GetPlayerStatusIcon(self:GetCurrentStatus()))
end

function StatusManager:UIOnMouseEnter()
  if self.control == nil then
    self:df("top level control not found")
    return
  end

  InitializeTooltip(InformationTooltip, self.control, TOPLEFT, 0, 0, BOTTOMRIGHT)
  SetTooltipText(InformationTooltip, zo_strformat(SI_PLAYER_STATUS_TOOLTIP, GetString("SI_PLAYERSTATUS", self:GetCurrentStatus())))
end

function StatusManager:UIOnMouseExit()
  ClearTooltip(InformationTooltip)
end

function StatusManager:OnShowMinBar()
  if self.control == nil then
    self:df("top level control not found")
    return
  end

  self.control:SetParent(CHAT_SYSTEM.minBar)
  self.control:ClearAnchors()
  self.control:SetAnchor(TOPLEFT, ZO_ChatWindowNumNotifications, BOTTOMLEFT, 0, 0)
  --- @type ButtonControl
  local openButton = GetControl(self.control, "ComboBoxOpen")
  if openButton == nil then
    self:d("Combo box open button not found.")
    return
  end

  openButton:SetHidden(true)
end

function StatusManager:OnHideMinBar()
  if self.control == nil then
    self:df("top level control not found")
    return
  end

  self.control:SetParent(CHAT_SYSTEM.control)
  self.control:ClearAnchors()
  self.control:SetAnchor(LEFT, ZO_ChatWindowNumNotifications, RIGHT, 2, 0)
  --- @type ButtonControl
  local openButton = GetControl(self.control, "ComboBoxOpen")
  if openButton == nil then
    self:d("Combo box open button not found.")
    return
  end

  openButton:SetHidden(false)
end
