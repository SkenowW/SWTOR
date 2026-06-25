-- ============================================================
--  SW:TOR RP — BOUTIQUE SERVEUR
--  lua/autorun/server/sv_swtor_shop.lua
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_BuyItem")
util.AddNetworkString("SWTOR_BuyResult")
util.AddNetworkString("SWTOR_OpenShop")

-- Inventaire joueur (en mémoire, persisté dans DB via JSON)
SWTOR.Inventories = SWTOR.Inventories or {}

local function GetInventory(ply)
    local sid = ply:SteamID()
    if not SWTOR.Inventories[sid] then
        -- Charger depuis DB
        local row = sql.QueryRow("SELECT * FROM swtor_players WHERE steamid = " .. sql.SQLStr(sid))
        if row and row.inventory and row.inventory ~= "" then
            SWTOR.Inventories[sid] = util.JSONToTable(row.inventory) or {}
        else
            SWTOR.Inventories[sid] = {}
        end
    end
    return SWTOR.Inventories[sid]
end

local function SaveInventory(ply)
    local sid = ply:SteamID()
    local inv = SWTOR.Inventories[sid] or {}
    -- Ajouter colonne si elle n'existe pas
    sql.Query("ALTER TABLE swtor_players ADD COLUMN inventory TEXT DEFAULT ''")  -- ignoré si existe
    sql.Query("UPDATE swtor_players SET inventory = " .. sql.SQLStr(util.TableToJSON(inv)) ..
              " WHERE steamid = " .. sql.SQLStr(sid))
end

-- Achat
net.Receive("SWTOR_BuyItem", function(len, ply)
    local itemId = net.ReadString()
    local ok, data = SWTOR.Shop.CanBuy(ply, itemId)

    net.Start("SWTOR_BuyResult")
    if not ok then
        net.WriteString("error")
        net.WriteString(data)
        net.Send(ply)
        return
    end

    local item = data
    -- Déduire crédits
    ply.swtor_credits = (ply.swtor_credits or 0) - item.price
    SWTOR.SavePlayer(ply)
    SWTOR.SyncPlayerData(ply)

    -- Donner l'item
    if item.weapon then
        ply:Give(item.weapon)
        SWTOR.Notify(ply, "⚔ " .. item.name .. " ajouté à votre inventaire.", "success")
    elseif item.use_fn then
        -- Consommable: ajouter à l'inventaire
        local inv = GetInventory(ply)
        inv[itemId] = (inv[itemId] or 0) + 1
        SaveInventory(ply)
        SWTOR.Notify(ply, "🎒 " .. item.name .. " dans votre inventaire.", "success")
    elseif item.title then
        ply.swtor_title = item.title
        SWTOR.SavePlayer(ply)
        SWTOR.Notify(ply, "🏅 Titre obtenu: " .. item.title, "success")
    end

    net.WriteString("success")
    net.WriteString("Achat réussi: " .. item.name .. " (-" .. item.price .. " cr)")
    net.Send(ply)
end)

-- Utiliser consommable
util.AddNetworkString("SWTOR_UseItem")
net.Receive("SWTOR_UseItem", function(len, ply)
    local itemId = net.ReadString()
    local item   = SWTOR.Shop.Items[itemId]
    if not item or not item.use_fn then return end

    local inv = GetInventory(ply)
    if not inv[itemId] or inv[itemId] <= 0 then
        SWTOR.Notify(ply, "Vous n'avez pas cet item.", "error")
        return
    end

    inv[itemId] = inv[itemId] - 1
    if inv[itemId] == 0 then inv[itemId] = nil end
    SaveInventory(ply)
    item.use_fn(ply)
end)

-- Envoyer l'inventaire au client sur demande
util.AddNetworkString("SWTOR_RequestInventory")
util.AddNetworkString("SWTOR_SendInventory")
net.Receive("SWTOR_RequestInventory", function(len, ply)
    local inv = GetInventory(ply)
    net.Start("SWTOR_SendInventory")
        net.WriteString(util.TableToJSON(inv))
    net.Send(ply)
end)

print("[SW:TOR] Boutique serveur chargée ✓")
