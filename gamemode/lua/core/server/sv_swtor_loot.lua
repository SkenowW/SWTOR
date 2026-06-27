-- ============================================================
--  SW:TOR RP — AURAS EXCLUSIVES + LOOT DROP SERVEUR
--  lua/autorun/server/sv_swtor_loot.lua
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_LootDrop")
util.AddNetworkString("SWTOR_LootEquip")
util.AddNetworkString("SWTOR_AuraUpdate")
util.AddNetworkString("SWTOR_SetAuraAdmin")

-- ============================================================
--  AURAS — ASSIGNATION ADMIN UNIQUEMENT
-- ============================================================

-- Auras exclusives : ne jamais apparaître dans RollItem
-- Assignées via commande console admin uniquement

concommand.Add("swtor_setaura", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then
        SWTOR.Notify(ply, "Permission refusée.", "error") return
    end
    local targetName = args[1]
    local auraKey    = args[2]
    local printFn    = IsValid(ply) and function(s) ply:ChatPrint(s) end or print

    if not targetName or not auraKey then
        printFn("[SWTOR] Usage: swtor_setaura <joueur> <aura_key>")
        printFn("  Auras exclusives: aura_furie | aura_mains | aura_empereur | aura_legende_jedi")
        printFn("  swtor_setaura <joueur> none  — pour retirer l'aura")
        return
    end

    -- Trouver le joueur
    local target = nil
    for _, p in ipairs(player.GetAll()) do
        if string.lower(p:Nick()):find(string.lower(targetName)) then
            target = p break
        end
    end
    if not IsValid(target) then
        printFn("[SWTOR] Joueur introuvable: " .. targetName) return
    end

    -- Retirer l'aura
    if auraKey == "none" or auraKey == "aucune" then
        target.swtor_aura = nil
        SWTOR.BroadcastAura(target, nil)
        SWTOR.SavePlayer(target)
        printFn("[SWTOR] Aura retirée de " .. target:Nick())
        SWTOR.Notify(target, "Votre aura a été retirée.", "info")
        return
    end

    -- Vérifier que l'aura existe
    local auraData = SWTOR.Loot and SWTOR.Loot.Items and SWTOR.Loot.Items[auraKey]
    if not auraData or auraData.type ~= "aura" then
        printFn("[SWTOR] Aura inconnue: " .. auraKey)
        return
    end

    -- Vérifier faction (optionnel — admin peut forcer)
    local factionOk = false
    for _, f in ipairs(auraData.factions or {}) do
        if f == target.swtor_faction then factionOk = true break end
    end
    if not factionOk then
        printFn("[SWTOR] ⚠ Aura hors faction assignée quand même (admin override).")
    end

    target.swtor_aura = auraKey
    SWTOR.BroadcastAura(target, auraKey)
    SWTOR.SavePlayer(target)
    printFn("[SWTOR] Aura '" .. auraData.name .. "' assignée à " .. target:Nick())
    SWTOR.Notify(target, "✦ Aura exclusive assignée: " .. auraData.name, "success")
end)

-- Lister les auras disponibles
concommand.Add("swtor_listauras", function(ply, cmd, args)
    local printFn = IsValid(ply) and function(s) ply:ChatPrint(s) end or print
    printFn("=== SW:TOR — Auras exclusives ===")
    if not SWTOR.Loot or not SWTOR.Loot.Items then return end
    for key, item in pairs(SWTOR.Loot.Items) do
        if item.type == "aura" and item.exclusive then
            printFn("  " .. key .. " — " .. item.name ..
                    " [" .. table.concat(item.factions, "/") .. "]")
        end
    end
    printFn("=== Auras lootables ===")
    -- Il n'y en a pas — toutes exclusive=true
    printFn("  Aucune aura lootable. Toutes sont exclusives.")
end)

-- ============================================================
--  BROADCAST AURA aux clients proches
-- ============================================================
function SWTOR.BroadcastAura(ply, auraKey)
    net.Start("SWTOR_AuraUpdate")
        net.WriteUInt(ply:EntIndex(), 16)
        net.WriteString(auraKey or "")
    net.Broadcast()
end

-- Envoyer toutes les auras actives à un joueur qui connecte
hook.Add("PlayerInitialSpawn", "SWTOR_SendAurasOnJoin", function(newPly)
    timer.Simple(3, function()
        if not IsValid(newPly) then return end
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) and p.swtor_aura and p.swtor_aura ~= "" then
                net.Start("SWTOR_AuraUpdate")
                    net.WriteUInt(p:EntIndex(), 16)
                    net.WriteString(p.swtor_aura)
                net.Send(newPly)
            end
        end
    end)
end)

-- ============================================================
--  LOOT DROP — Récompense après kill/holocron/event
-- ============================================================
SWTOR.LootCooldowns = {}  -- Anti-spam drop

-- ============================================================
--  VÉRIFICATION PERMISSION HRP POUR ITEMS EXCLUSIFS
-- ============================================================
local function HasHRPAccess(ply, item)
    if not item.hrp_req then return true end  -- Pas de restriction
    if not SWTOR.HRP then return false end

    local minLevel = item.hrp_req_min_level or 5  -- Défaut = fondateur (5)
    local plyLevel = SWTOR.HRP.GetLevel(ply)
    return plyLevel >= minLevel
end

-- ============================================================
--  DROP LOOT AVEC drop_weight (1% / 4% selon item)
-- ============================================================
local function GiveLootDrop(ply, reason)
    if not IsValid(ply) then return end
    local sid = ply:SteamID()

    -- Cooldown 60s entre drops
    if SWTOR.LootCooldowns[sid] and SWTOR.LootCooldowns[sid] > CurTime() then return end
    SWTOR.LootCooldowns[sid] = CurTime() + 60

    local faction = ply.swtor_faction or ""
    if faction == "" then return end

    -- Construire le pool uniquement d'items lootables
    -- Pondération par drop_weight (défaut=10 si non spécifié)
    local pool = {}
    for key, item in pairs(SWTOR.Loot.Items) do
        -- Exclure non-lootables et exclusifs
        if item.lootable == false or item.exclusive then continue end
        -- Vérifier la faction
        local factionOk = false
        for _, f in ipairs(item.factions or {}) do
            if f == faction then factionOk = true break end
        end
        if not factionOk then continue end
        -- Ajouter selon le poids
        local weight = item.drop_weight or 10
        for i = 1, weight do
            table.insert(pool, key)
        end
    end

    if #pool == 0 then return end

    -- Roll dans le pool pondéré
    local itemKey  = pool[math.random(#pool)]
    local itemData = SWTOR.Loot.Items[itemKey]
    if not itemData then return end

    -- Vérifier que le joueur ne possède pas déjà cet item
    ply.swtor_cosmetics = ply.swtor_cosmetics or {}
    if ply.swtor_cosmetics[itemKey] then
        -- Déjà possédé → reroll une fois
        local newKey = pool[math.random(#pool)]
        if ply.swtor_cosmetics[newKey] then return end  -- Pas de chance
        itemKey  = newKey
        itemData = SWTOR.Loot.Items[itemKey]
        if not itemData then return end
    end

    ply.swtor_cosmetics[itemKey] = true

    -- Notifier avec la bonne rareté
    net.Start("SWTOR_LootDrop")
        net.WriteString(itemKey)
        net.WriteString(itemData.name)
        net.WriteString(itemData.rarity or "transcendant")
        net.WriteString(itemData.desc or "")
    net.Send(ply)

    SWTOR.SavePlayer(ply)

    -- Log si item rare (drop_weight <= 4)
    if (itemData.drop_weight or 10) <= 4 then
        print("[SW:TOR LOOT RARE] " .. ply:Nick() ..
              " a obtenu : " .. itemData.name ..
              " (poids=" .. (itemData.drop_weight or "?") .. ")")
    end
end

-- Drop sur kill
hook.Add("PlayerDeath", "SWTOR_LootOnKill", function(victim, inflictor, attacker)
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        -- 30% chance de drop sur kill
        if math.random(100) <= 30 then
            GiveLootDrop(attacker, "kill")
        end
    end
end)

-- Drop sur victoire de duel
hook.Add("SWTOR_DuelWon", "SWTOR_LootOnDuel", function(winner)
    -- 60% chance sur duel
    if math.random(100) <= 60 then
        GiveLootDrop(winner, "duel")
    end
end)

-- Commande admin pour donner un cosmétique précis
concommand.Add("swtor_givecosmetique", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then return end
    local targetName = args[1]
    local itemKey    = args[2]
    local printFn    = IsValid(ply) and function(s) ply:ChatPrint(s) end or print

    if not targetName or not itemKey then
        printFn("[SWTOR] Usage: swtor_givecosmetique <joueur> <item_key>")
        return
    end

    local target = nil
    for _, p in ipairs(player.GetAll()) do
        if string.lower(p:Nick()):find(string.lower(targetName)) then target=p break end
    end
    if not IsValid(target) then printFn("[SWTOR] Introuvable: "..targetName) return end

    local item = SWTOR.Loot and SWTOR.Loot.Items and SWTOR.Loot.Items[itemKey]
    if not item then printFn("[SWTOR] Item inconnu: "..itemKey) return end
    if item.exclusive then printFn("[SWTOR] ⚠ Item exclusif — utilisez swtor_setaura à la place.") return end

    target.swtor_cosmetics = target.swtor_cosmetics or {}
    target.swtor_cosmetics[itemKey] = true
    SWTOR.SavePlayer(target)

    net.Start("SWTOR_LootDrop")
        net.WriteString(itemKey)
        net.WriteString(item.name)
        net.WriteString(item.rarity or "commun")
        net.WriteString(item.desc or "")
    net.Send(target)

    printFn("[SWTOR] Cosmétique '" .. item.name .. "' donné à " .. target:Nick())
end)

-- ============================================================
--  ÉQUIPER UN COSMÉTIQUE (reçu du client)
-- ============================================================
net.Receive("SWTOR_LootEquip", function(len, ply)
    local itemKey = net.ReadString()
    local item    = SWTOR.Loot and SWTOR.Loot.Items and SWTOR.Loot.Items[itemKey]
    if not item then return end
    -- Bloquer si exclusif ou si niveau HRP insuffisant
    if item.exclusive then
        SWTOR.Notify(ply, "Cet item est exclusif — assignation admin uniquement.", "error")
        return
    end
    -- Vérifier permission HRP si drop_weight <= 4 (super rare)
    -- (les items lootables n'ont pas de hrp_req, seulement les exclusifs)

    -- Vérifier possession
    ply.swtor_cosmetics = ply.swtor_cosmetics or {}
    if not ply.swtor_cosmetics[itemKey] then
        SWTOR.Notify(ply, "Vous ne possédez pas ce cosmétique.", "error") return
    end

    -- Appliquer selon le type
    if item.type == "sabre_color" or item.type == "sabre_effect" then
        ply.swtor_sabre_skin = itemKey
        -- Mettre à jour la couleur du sabre actif
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep.SaberStyle then
            local eff = item.effect or {}
            wep:SetNWInt("sc_r", eff.r or 255)
            wep:SetNWInt("sc_g", eff.g or 30)
            wep:SetNWInt("sc_b", eff.b or 30)
            wep:SetNWBool("saber_flicker", eff.flicker or false)
            wep:SetNWBool("saber_trail",   eff.trail   or false)
            wep:SetNWBool("saber_dark",    eff.dark    or false)
        end
        SWTOR.Notify(ply, "✦ Cristal équipé: " .. item.name, "success")

    elseif item.type == "movement_trail" then
        ply.swtor_trail_skin = itemKey
        SWTOR.Notify(ply, "✦ Trace équipée: " .. item.name, "success")

    elseif item.type == "footprint" then
        ply.swtor_footprint_skin = itemKey
        SWTOR.Notify(ply, "✦ Empreintes équipées: " .. item.name, "success")
    end

    SWTOR.SavePlayer(ply)
end)

print("[SW:TOR] Loot serveur chargé ✓")
print("  swtor_setaura    <joueur> <aura_key>")
print("  swtor_listauras")
print("  swtor_givecosmetique <joueur> <item_key>")

-- ============================================================
--  COMMANDES ADMIN — DONNER ITEMS EXCLUSIFS FONDATEURS
-- ============================================================

-- swtor_setcosmetic <joueur> <item_key>
-- Donne n'importe quel item (lootable ou exclusif) via admin
concommand.Add("swtor_setcosmetic", function(ply, cmd, args)
    local printFn = IsValid(ply) and function(s) ply:ChatPrint(s) end or print

    -- Seuls fondateurs et responsables (niveau 4+) ou console
    if IsValid(ply) then
        local level = SWTOR.HRP and SWTOR.HRP.GetLevel(ply) or 0
        if level < 4 then
            printFn("[LOOT] Fondateur ou Responsable requis.")
            return
        end
    end

    local targetName = args[1]
    local itemKey    = args[2]

    if not targetName or not itemKey then
        printFn("[LOOT] Usage: swtor_setcosmetic <joueur> <item_key>")
        printFn("  Items exclusifs fondateur:")
        printFn("  Sabres  : lame_blanche | lame_noire | lame_eclipse | lame_originelle")
        printFn("  Effets  : lame_mythique | lame_transcendant")
        printFn("  Traces  : trace_glitch")
        printFn("  Emprein.: empreintes_feu | empreintes_force | empreintes_void")
        return
    end

    local target = nil
    for _, p in ipairs(player.GetAll()) do
        if string.lower(p:Nick()):find(string.lower(targetName)) then target=p break end
    end
    if not IsValid(target) then printFn("[LOOT] Joueur introuvable: "..targetName) return end

    local item = SWTOR.Loot and SWTOR.Loot.Items and SWTOR.Loot.Items[itemKey]
    if not item then printFn("[LOOT] Item inconnu: "..itemKey) return end

    target.swtor_cosmetics = target.swtor_cosmetics or {}
    target.swtor_cosmetics[itemKey] = true
    SWTOR.SavePlayer(target)

    net.Start("SWTOR_LootDrop")
        net.WriteString(itemKey)
        net.WriteString(item.name)
        net.WriteString(item.rarity or "transcendant")
        net.WriteString(item.desc or "")
    net.Send(target)

    printFn("[LOOT] ✔ " .. item.name .. " donné à " .. target:Nick())
end)

-- swtor_listcosmetique <joueur>
concommand.Add("swtor_listcosmetique", function(ply, cmd, args)
    local printFn = IsValid(ply) and function(s) ply:ChatPrint(s) end or print
    local targetName = args[1]
    if not targetName then
        printFn("[LOOT] Usage: swtor_listcosmetique <joueur>") return
    end
    for _, p in ipairs(player.GetAll()) do
        if string.lower(p:Nick()):find(string.lower(targetName)) then
            local cosm = p.swtor_cosmetics or {}
            printFn("=== Cosmétiques de " .. p:Nick() .. " ===")
            local count = 0
            for key, _ in pairs(cosm) do
                local item = SWTOR.Loot and SWTOR.Loot.Items and SWTOR.Loot.Items[key]
                printFn("  " .. key .. (item and (" — " .. item.name) or ""))
                count = count + 1
            end
            printFn("Total: " .. count .. " item(s)")
            return
        end
    end
    printFn("[LOOT] Introuvable: " .. targetName)
end)

print("[SW:TOR Loot] Commandes fondateur ajoutées:")
print("  swtor_setcosmetic <joueur> <item_key>")
print("  swtor_listcosmetique <joueur>")
