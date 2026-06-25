-- ============================================================
--  SW:TOR RP — MENU BOUTIQUE CLIENT
--  lua/autorun/client/cl_swtor_shop.lua
-- ============================================================

if SERVER then return end

local Inventory = {}

net.Receive("SWTOR_SendInventory", function()
    Inventory = util.JSONToTable(net.ReadString()) or {}
end)

net.Receive("SWTOR_BuyResult", function()
    local status = net.ReadString()
    local msg    = net.ReadString()
    local col    = status == "success" and Color(80,220,80) or Color(220,80,80)
    chat.AddText(col, "[BOUTIQUE] " .. msg)
end)

local function OpenShop()
    if not SWTOR or not SWTOR.Shop then return end
    local faction = LocalData and LocalData.faction or ""
    if faction == "" then
        chat.AddText(Color(255,150,50), "[SW:TOR] Rejoignez une faction d'abord.")
        return
    end

    -- Demander inventaire à jour
    net.Start("SWTOR_RequestInventory") net.SendToServer()

    if IsValid(SWTOR_ShopPanel) then SWTOR_ShopPanel:Remove() end

    local sw, sh = ScrW(), ScrH()
    local W, H   = 720, 560
    local fColor = SWTOR.Factions[faction] and SWTOR.Factions[faction].color or Color(150,150,150)

    local frame = vgui.Create("DFrame")
    frame:SetPos((sw-W)/2, (sh-H)/2)
    frame:SetSize(W, H)
    frame:SetTitle("Boutique — " .. (SWTOR.Factions[faction] and SWTOR.Factions[faction].name or ""))
    frame:MakePopup()
    SWTOR_ShopPanel = frame
    frame.Paint = function(s,w,h)
        draw.RoundedBox(8,0,0,w,h,Color(8,10,22,248))
        surface.SetDrawColor(fColor.r,fColor.g,fColor.b,140)
        surface.DrawOutlinedRect(0,0,w,h,2)
    end

    -- Barre de crédits
    local credBar = vgui.Create("DPanel", frame)
    credBar:SetPos(0,24) credBar:SetSize(W,30)
    credBar.Paint = function(s,w,h)
        draw.RoundedBox(0,0,0,w,h,Color(20,20,40,200))
        local creds = LocalData and LocalData.credits or 0
        draw.SimpleText("💰 " .. creds .. " crédits disponibles",
            "SWTOR_HUD_Medium", w/2, h/2, Color(220,180,40), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Catégories
    local cats = { "arme", "equipement", "consommable", "titre" }
    local catLabels = { arme="⚔ Armes", equipement="🛡 Équipement", consommable="💊 Consommables", titre="🏅 Titres" }
    local selectedCat = "arme"

    local tabBar = vgui.Create("DPanel", frame)
    tabBar:SetPos(0,54) tabBar:SetSize(W,32)
    tabBar.Paint = function(s,w,h) draw.RoundedBox(0,0,0,w,h,Color(15,15,30,220)) end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(0,86) scroll:SetSize(W,H-86)

    local function RebuildItems()
        scroll:Clear()
        local items = SWTOR.Shop.GetItemsForFaction(faction)
        for _, item in ipairs(items) do
            if item.category ~= selectedCat then continue end

            local row = vgui.Create("DPanel", scroll)
            row:SetHeight(64)
            row:Dock(TOP)
            row:DockMargin(6,3,6,0)

            local canAfford = (LocalData and LocalData.credits or 0) >= item.price
            local gradeOk   = not item.grade_req or (LocalData and LocalData.grade or 1) >= item.grade_req
            local available = canAfford and gradeOk

            row.Paint = function(s,w,h)
                local bg = available and Color(20,25,45,200) or Color(15,15,25,180)
                draw.RoundedBox(6,0,0,w,h,bg)
                surface.SetDrawColor(fColor.r,fColor.g,fColor.b, available and 100 or 30)
                surface.DrawOutlinedRect(0,0,w,h,1)

                draw.SimpleText(item.name, "SWTOR_HUD_Big", 12, 14,
                    Color(255,255,255, available and 255 or 100), TEXT_ALIGN_LEFT)
                draw.SimpleText(item.desc or "", "SWTOR_HUD_Small", 12, 36,
                    Color(160,160,160, available and 200 or 80), TEXT_ALIGN_LEFT)

                -- Prix
                local priceColor = canAfford and Color(100,220,100) or Color(220,80,80)
                draw.SimpleText(item.price .. " cr", "SWTOR_HUD_Big", w-100, h/2,
                    priceColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                -- Grade requis
                if item.grade_req then
                    local gColor = gradeOk and Color(100,200,100) or Color(220,100,50)
                    draw.SimpleText("Grade " .. item.grade_req .. "+", "SWTOR_HUD_Small",
                        w-100, h/2 + 16, gColor, TEXT_ALIGN_LEFT)
                end

                -- Bouton acheter
                if available then
                    draw.RoundedBox(5, w-80, (h-28)/2, 72, 28, Color(fColor.r,fColor.g,fColor.b,180))
                    draw.SimpleText("ACHETER", "SWTOR_HUD_Small", w-44, h/2,
                        Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end

            if available then
                row:SetCursor("hand")
                local itemId = item.id
                row.OnMousePressed = function(s, key)
                    if key == MOUSE_LEFT then
                        net.Start("SWTOR_BuyItem")
                            net.WriteString(itemId)
                        net.SendToServer()
                        surface.PlaySound("buttons/button15.wav")
                        timer.Simple(0.5, RebuildItems)
                    end
                end
            end
        end
    end

    -- Tabs
    local tabW = W / #cats
    for i, cat in ipairs(cats) do
        local tab = vgui.Create("DButton", tabBar)
        tab:SetPos((i-1)*tabW, 0)
        tab:SetSize(tabW, 32)
        tab:SetText("")
        local c = cat
        tab.Paint = function(s,w,h)
            local active = selectedCat == c
            draw.RoundedBox(0,0,0,w,h, active
                and Color(fColor.r,fColor.g,fColor.b,160)
                or  Color(20,20,40,0))
            draw.SimpleText(catLabels[c] or c, "SWTOR_HUD_Medium", w/2, h/2,
                Color(255,255,255, active and 255 or 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            if active then
                surface.SetDrawColor(fColor.r,fColor.g,fColor.b,255)
                surface.DrawRect(0,h-2,w,2)
            end
        end
        tab.DoClick = function()
            selectedCat = c
            RebuildItems()
        end
    end

    RebuildItems()
end

concommand.Add("swtor_shop",    OpenShop)
concommand.Add("swtor_boutique", OpenShop)

print("[SW:TOR] Menu boutique client chargé ✓ — commande: swtor_shop")
