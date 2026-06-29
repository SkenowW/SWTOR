-- ============================================================
--  SW:TOR RP — CANDIDATURE (CLIENT) + INVENTAIRE
--  lua/autorun/client/cl_swtor_application.lua
-- ============================================================

if SERVER then return end

net.Receive("SWTOR_ApplicationResult", function()
    local status = net.ReadString()
    local msg    = net.ReadString()
    local colors = {
        success  = Color(80,220,80),
        error    = Color(220,80,80),
        pending  = Color(220,180,40),
        rejected = Color(220,80,80),
    }
    chat.AddText(colors[status] or Color(200,200,200), "[CANDIDATURE] " .. msg)
    if status == "success" then
        surface.PlaySound("buttons/button17.wav")
    end
end)

-- ============================================================
--  MENU CANDIDATURE FACTION
-- ============================================================
local function OpenApplicationMenu()
    if not SWTOR or not SWTOR.Factions then return end
    if IsValid(SWTOR_AppMenu) then SWTOR_AppMenu:Remove() end

    local sw, sh = ScrW(), ScrH()
    local W, H   = 600, 500

    local frame = vgui.Create("DFrame")
    frame:SetPos((sw-W)/2, (sh-H)/2)
    frame:SetSize(W, H)
    frame:SetTitle("Rejoindre une Faction")
    frame:MakePopup()
    SWTOR_AppMenu = frame
    frame.Paint = function(s,w,h)
        draw.RoundedBox(8,0,0,w,h,Color(8,10,22,245))
        surface.SetDrawColor(100,80,40,140)
        surface.DrawOutlinedRect(0,0,w,h,2)
    end

    -- Liste factions
    local selected = nil
    local factionBtns = {}

    local factionPanel = vgui.Create("DPanel", frame)
    factionPanel:SetPos(8, 30) factionPanel:SetSize(W-16, 200)
    factionPanel.Paint = function(s,w,h) end

    local fList = { "empire", "republique", "mandalorien" }
    local btnW  = (W-16) / #fList

    for i, fkey in ipairs(fList) do
        local f    = SWTOR.Factions[fkey]
        local btn  = vgui.Create("DButton", factionPanel)
        btn:SetPos((i-1)*btnW, 0) btn:SetSize(btnW-4, 190)
        btn:SetText("")

        local hov = false
        btn.OnCursorEntered = function() hov = true  end
        btn.OnCursorExited  = function() hov = false end

        local fk = fkey
        btn.Paint = function(s,w,h)
            local active = selected == fk
            local fc     = f.color
            draw.RoundedBox(8,0,0,w,h, active
                and Color(fc.r*0.4,fc.g*0.4,fc.b*0.4,230)
                or (hov and Color(fc.r*0.2,fc.g*0.2,fc.b*0.2,200)
                        or  Color(12,12,25,200)))
            surface.SetDrawColor(fc.r,fc.g,fc.b, active and 255 or (hov and 150 or 60))
            surface.DrawOutlinedRect(0,0,w,h, active and 2 or 1)

            draw.SimpleText(f.name, "SWTOR_HUD_Big", w/2, 30,
                Color(255,255,255), TEXT_ALIGN_CENTER)
            draw.SimpleText(SWTOR.GetMaxGrade(fk) .. " grades", "SWTOR_HUD_Small",
                w/2, 55, Color(fc.r,fc.g,fc.b), TEXT_ALIGN_CENTER)

            -- Planètes
            local planetes = SWTOR.GetFactionPlanets(fk)
            local pNames = {}
            for _, p in pairs(planetes) do table.insert(pNames, p.name) end
            draw.SimpleText(table.concat(pNames, ", "), "SWTOR_HUD_Small",
                w/2, 75, Color(160,160,160), TEXT_ALIGN_CENTER)

            -- Description courte
            local descLines = string.Explode("\n", f.description:sub(1,100))
            for j, line in ipairs(descLines) do
                draw.SimpleText(line, "SWTOR_HUD_Small", w/2, 100 + (j-1)*18,
                    Color(180,180,180), TEXT_ALIGN_CENTER)
            end
        end
        btn.DoClick = function() selected = fk end
        factionBtns[fkey] = btn
    end

    -- Champ motivation
    local motLabel = vgui.Create("DLabel", frame)
    motLabel:SetPos(8, 240) motLabel:SetSize(W-16, 20)
    motLabel:SetText("Motivation / Présentation de votre personnage:")
    motLabel:SetFont("SWTOR_HUD_Medium")
    motLabel:SetTextColor(Color(200,200,200))

    local motEntry = vgui.Create("DTextEntry", frame)
    motEntry:SetPos(8, 262) motEntry:SetSize(W-16, 120)
    motEntry:SetMultiline(true)
    motEntry:SetPlaceholderText("Décrivez votre personnage et pourquoi il rejoint cette faction...")
    motEntry:SetFont("SWTOR_HUD_Small")

    -- Bouton envoyer
    local sendBtn = vgui.Create("DButton", frame)
    sendBtn:SetPos(8, 394) sendBtn:SetSize(W-16, 40)
    sendBtn:SetText("")
    sendBtn.Paint = function(s,w,h)
        draw.RoundedBox(6,0,0,w,h, Color(50,120,50,200))
        draw.SimpleText("ENVOYER LA CANDIDATURE", "SWTOR_HUD_Big",
            w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    sendBtn.DoClick = function()
        if not selected then
            chat.AddText(Color(255,150,50), "[SW:TOR] Sélectionnez une faction.")
            return
        end
        local mot = motEntry:GetValue()
        if #mot < 10 then
            chat.AddText(Color(255,150,50), "[SW:TOR] Écrivez une motivation (min 10 caractères).")
            return
        end
        net.Start("SWTOR_ApplyFaction")
            net.WriteString(selected)
            net.WriteString(mot)
        net.SendToServer()
        frame:Remove()
    end
end

concommand.Add("swtor_apply",     OpenApplicationMenu)
concommand.Add("swtor_candidater", OpenApplicationMenu)

-- ============================================================
--  INVENTAIRE CLIENT
-- ============================================================

-- On demande l'inventaire au serveur
local function RequestInventory()
    net.Start("SWTOR_RequestInventory") 
    net.SendToServer()
end

concommand.Add("swtor_inventory",  RequestInventory)
concommand.Add("swtor_inventaire", RequestInventory)

-- Le serveur nous répond, on construit l'interface
net.Receive("SWTOR_SendInventory", function()
    -- On lit le JSON et on le transforme en table
    local invJSON = net.ReadString()
    local Inventory = util.JSONToTable(invJSON) or {}

    if IsValid(SWTOR_InvMenu) then SWTOR_InvMenu:Remove() end
    
    local sw, sh = ScrW(), ScrH()
    local W, H   = 400, 400
    local frame  = vgui.Create("DFrame")
    frame:SetPos((sw-W)/2, (sh-H)/2)
    frame:SetSize(W, H)
    frame:SetTitle("Inventaire")
    frame:MakePopup()
    SWTOR_InvMenu = frame
    frame.Paint = function(s,w,h)
        draw.RoundedBox(8,0,0,w,h,Color(8,10,22,245))
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL) scroll:DockMargin(5,28,5,5)

    local hasItems = false
    -- La boucle utilise maintenant notre table sécurisée 'Inventory'
    for itemId, qty in pairs(Inventory) do
        if qty and qty > 0 then
            hasItems = true
            local item = SWTOR and SWTOR.Shop and SWTOR.Shop.Items and SWTOR.Shop.Items[itemId]
            local name = item and item.name or itemId

            local row = vgui.Create("DButton", scroll)
            row:SetText("") row:SetHeight(48) row:Dock(TOP) row:DockMargin(0,2,0,0)

            local iid = itemId
            row.Paint = function(s,w,h)
                draw.RoundedBox(5,0,0,w,h,Color(15,18,35,200))
                draw.SimpleText(name, "SWTOR_HUD_Medium", 12, h/2, Color(220,220,220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText("x" .. qty, "SWTOR_HUD_Big", w-80, h/2, Color(100,220,100), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.RoundedBox(4, w-65, (h-24)/2, 58, 24, Color(50,100,50,180))
                draw.SimpleText("UTILISER", "SWTOR_HUD_Small", w-36, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            row.DoClick = function()
                net.Start("SWTOR_UseItem")
                    net.WriteString(iid)
                net.SendToServer()
                frame:Remove()
            end
        end
    end

    if not hasItems then
        local lbl = vgui.Create("DLabel", scroll)
        lbl:Dock(FILL)
        lbl:SetText("Inventaire vide.\nAchetez des consommables dans la boutique.")
        lbl:SetFont("SWTOR_HUD_Medium")
        lbl:SetContentAlignment(5)
        lbl:SetTextColor(Color(140,140,140))
    end
end)

print("[SW:TOR] Candidature & Inventaire client chargés ✓")
print("  swtor_apply | swtor_inventory")
