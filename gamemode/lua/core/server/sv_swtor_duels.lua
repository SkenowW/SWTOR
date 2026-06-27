-- ============================================================
--  SW:TOR RP — SYSTÈME DE DUELS 1v1
--  lua/autorun/server/sv_swtor_duels.lua
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_DuelRequest")
util.AddNetworkString("SWTOR_DuelResponse")
util.AddNetworkString("SWTOR_DuelStart")
util.AddNetworkString("SWTOR_DuelEnd")
util.AddNetworkString("SWTOR_DuelStatus")

SWTOR.Duels        = {}   -- [steamid] = { opponent, startTime, hp1, hp2 }
SWTOR.DuelRequests = {}   -- [steamid_target] = { from, time }

-- ============================================================
--  DEMANDE DE DUEL (commande !duel ou via chat)
-- ============================================================
local function SendDuelRequest(challenger, target)
    if not IsValid(challenger) or not IsValid(target) then return end
    if challenger == target then
        SWTOR.Notify(challenger, "Vous ne pouvez pas vous défier vous-même.", "error")
        return
    end
    -- Déjà en duel ?
    if SWTOR.Duels[challenger:SteamID()] then
        SWTOR.Notify(challenger, "Vous êtes déjà en duel.", "error") return
    end
    if SWTOR.Duels[target:SteamID()] then
        SWTOR.Notify(challenger, target:Nick() .. " est déjà en duel.", "error") return
    end
    -- Distance max 800u
    if challenger:GetPos():Distance(target:GetPos()) > 800 then
        SWTOR.Notify(challenger, "Trop loin pour défier " .. target:Nick() .. " (max 800u).", "error")
        return
    end

    local key = challenger:SteamID() .. "_" .. target:SteamID()
    SWTOR.DuelRequests[key] = { from = challenger, time = CurTime() + 30 }

    -- Notifier les deux
    SWTOR.Notify(challenger, "⚔ Défi envoyé à " .. target:Nick() .. " — 30s pour accepter.", "info")
    SWTOR.Notify(target, "⚔ " .. challenger:Nick() .. " vous défie en duel ! Tapez /duel accept pour accepter.", "warning")

    -- Auto-expire
    timer.Simple(30, function()
        if SWTOR.DuelRequests[key] then
            SWTOR.DuelRequests[key] = nil
            if IsValid(challenger) then
                SWTOR.Notify(challenger, "⏱ Défi à " .. target:Nick() .. " expiré.", "warning")
            end
        end
    end)
end

local function StartDuel(p1, p2)
    local id1 = p1:SteamID()
    local id2 = p2:SteamID()

    -- Trouver un point médian pour le duel
    local midPos = (p1:GetPos() + p2:GetPos()) * 0.5

    SWTOR.Duels[id1] = { opponent = p2, start = CurTime(), loser = nil }
    SWTOR.Duels[id2] = { opponent = p1, start = CurTime(), loser = nil }

    -- Restaurer HP complets
    SWTOR.ApplyClassStats(p1)
    SWTOR.ApplyClassStats(p2)

    -- Countdown + annonce
    for i = 3, 1, -1 do
        timer.Simple(3-i, function()
            if IsValid(p1) then SWTOR.Notify(p1, "⚔ Duel dans " .. i .. "s...", "warning") end
            if IsValid(p2) then SWTOR.Notify(p2, "⚔ Duel dans " .. i .. "s...", "warning") end
        end)
    end

    timer.Simple(3, function()
        if not IsValid(p1) or not IsValid(p2) then return end
        SWTOR.Notify(p1, "⚔ DUEL COMMENCE ! vs " .. p2:Nick(), "success")
        SWTOR.Notify(p2, "⚔ DUEL COMMENCE ! vs " .. p1:Nick(), "success")

        -- Annonce globale
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("⚔ DUEL: " .. p1:Nick() .. " [" ..
                (SWTOR.Classes[p1.swtor_class or ""] and SWTOR.Classes[p1.swtor_class].name or "?") ..
                "] vs " .. p2:Nick() .. " [" ..
                (SWTOR.Classes[p2.swtor_class or ""] and SWTOR.Classes[p2.swtor_class].name or "?") ..
                "]")
        end
    end)

    -- Timeout 5min
    timer.Create("SWTOR_Duel_" .. id1, 300, 1, function()
        if SWTOR.Duels[id1] then
            SWTOR.EndDuel(p1, p2, nil)  -- Match nul
        end
    end)
end

function SWTOR.EndDuel(p1, p2, loser)
    local id1 = p1 and p1:SteamID() or ""
    local id2 = p2 and p2:SteamID() or ""

    SWTOR.Duels[id1] = nil
    SWTOR.Duels[id2] = nil
    timer.Remove("SWTOR_Duel_" .. id1)

    if not loser then
        -- Match nul
        if IsValid(p1) then SWTOR.Notify(p1, "⚔ Duel terminé — Match nul !", "warning") end
        if IsValid(p2) then SWTOR.Notify(p2, "⚔ Duel terminé — Match nul !", "warning") end
        return
    end

    local winner = (loser == p1) and p2 or p1
    local loserP = loser

    -- Stats duels
    if IsValid(winner) then
        winner.swtor_duels_won  = (winner.swtor_duels_won  or 0) + 1
        winner.swtor_xp         = (winner.swtor_xp         or 0) + 150
        winner.swtor_credits    = (winner.swtor_credits     or 0) + 200
        SWTOR.SavePlayer(winner)
        SWTOR.SyncPlayerData(winner)
        SWTOR.Notify(winner, "🏆 Victoire ! +150 XP, +200 crédits", "success")
        -- Restaurer HP
        SWTOR.ApplyClassStats(winner)
    end
    if IsValid(loserP) then
        loserP.swtor_duels_lost = (loserP.swtor_duels_lost or 0) + 1
        SWTOR.SavePlayer(loserP)
        SWTOR.SyncPlayerData(loserP)
        SWTOR.Notify(loserP, "💀 Défaite. Mieux la prochaine fois.", "error")
        SWTOR.ApplyClassStats(loserP)
    end

    -- Annonce globale
    if IsValid(winner) and IsValid(loserP) then
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint("🏆 DUEL: " .. winner:Nick() .. " a vaincu " .. loserP:Nick() .. " !")
        end
    end
end

-- ============================================================
--  MORT EN DUEL — ne pas mourir vraiment, juste perdre
-- ============================================================
hook.Add("PlayerDeath", "SWTOR_DuelDeath", function(victim, inflictor, attacker)
    local vid = victim:SteamID()
    if not SWTOR.Duels[vid] then return end  -- Pas en duel

    local duelData = SWTOR.Duels[vid]
    local opponent = duelData.opponent

    -- Annuler la mort
    timer.Simple(0, function()
        if IsValid(victim) then
            victim:Spawn()
            victim:SetHealth(1)
        end
    end)

    -- Terminer le duel
    if IsValid(opponent) then
        SWTOR.EndDuel(victim, opponent, victim)
    else
        SWTOR.Duels[vid] = nil
    end

    -- Bloquer les stats de mort normales pendant un duel
    return true
end)

-- ============================================================
--  HOOKS CHAT — commandes duel
-- ============================================================
hook.Add("PlayerSay", "SWTOR_DuelCommands", function(ply, text)
    local ltext = string.lower(text)

    -- /duel <nom>
    if string.sub(ltext, 1, 6) == "/duel " then
        local targetName = string.sub(text, 7)
        for _, p in ipairs(player.GetAll()) do
            if string.lower(p:Nick()):find(string.lower(targetName)) and p ~= ply then
                SendDuelRequest(ply, p)
                return ""
            end
        end
        SWTOR.Notify(ply, "Joueur introuvable: " .. targetName, "error")
        return ""
    end

    -- /duel accept
    if ltext == "/duel accept" then
        for key, req in pairs(SWTOR.DuelRequests) do
            local target_sid = string.match(key, "._(.+)")
            if target_sid == ply:SteamID() and CurTime() < req.time then
                local challenger = req.from
                SWTOR.DuelRequests[key] = nil
                if IsValid(challenger) then
                    StartDuel(challenger, ply)
                end
                return ""
            end
        end
        SWTOR.Notify(ply, "Aucune demande de duel en attente.", "error")
        return ""
    end

    -- /duel forfeit (abandon)
    if ltext == "/duel forfeit" or ltext == "/duel abandon" then
        local vid = ply:SteamID()
        if SWTOR.Duels[vid] then
            local opponent = SWTOR.Duels[vid].opponent
            SWTOR.EndDuel(ply, opponent, ply)
            SWTOR.Notify(ply, "Vous avez abandonné le duel.", "warning")
        else
            SWTOR.Notify(ply, "Vous n'êtes pas en duel.", "error")
        end
        return ""
    end
end)

-- ============================================================
--  RESTREINDRE LE COMBAT AUX DUELISTES
-- ============================================================
hook.Add("PlayerShouldTakeDamage", "SWTOR_DuelDamage", function(victim, attacker)
    if not attacker:IsPlayer() then return end
    local vid = victim:SteamID()
    local aid = attacker:SteamID()

    local victimDuel   = SWTOR.Duels[vid]
    local attackerDuel = SWTOR.Duels[aid]

    -- Si l'un est en duel mais pas l'autre → pas de dégâts
    if victimDuel and not attackerDuel then return false end
    if attackerDuel and not victimDuel then return false end

    -- Si les deux sont en duel mais pas l'un contre l'autre → pas de dégâts
    if victimDuel and attackerDuel then
        if victimDuel.opponent ~= attacker or attackerDuel.opponent ~= victim then
            return false
        end
    end
end)

hook.Add("PlayerDisconnected", "SWTOR_DuelCleanup", function(ply)
    local sid = ply:SteamID()
    if SWTOR.Duels[sid] then
        local opponent = SWTOR.Duels[sid].opponent
        if IsValid(opponent) then
            SWTOR.EndDuel(ply, opponent, ply) -- L'adversaire gagne par défaut
            SWTOR.Notify(opponent, "Votre adversaire s'est déconnecté. Duel annulé.", "info")
        end
        SWTOR.Duels[sid] = nil
    end
    -- Nettoyer aussi si le joueur était la cible
    for k, v in pairs(SWTOR.Duels) do
        if v.opponent == ply then
            SWTOR.Duels[k] = nil
        end
    end
end)

print("[SW:TOR] Système de duels chargé ✓")
print("  /duel <nom>   — Défier un joueur")
print("  /duel accept  — Accepter un duel")
print("  /duel forfeit — Abandonner")
