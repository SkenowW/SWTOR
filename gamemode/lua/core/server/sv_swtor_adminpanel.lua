-- ============================================================
--  SW:TOR RP - PANEL ADMIN COMPLET
--  Fichier: lua/autorun/server/sv_swtor_adminpanel.lua
--  Coller dans: garrysmod/lua/autorun/server/
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_AdminAction")
util.AddNetworkString("SWTOR_AdminGetPlayers")
util.AddNetworkString("SWTOR_AdminPlayersData")

-- ============================================================
--  COMMANDES CONSOLE ADMIN
-- ============================================================

-- !swtor_setfaction <joueur> <faction>
concommand.Add("swtor_setfaction", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then
        ply:ChatPrint("[SWTOR] Permission refusée.")
        return
    end
    local targetName = args[1]
    local factionKey = args[2]
    if not targetName or not factionKey then
        if IsValid(ply) then
            ply:ChatPrint("[SWTOR] Usage: swtor_setfaction <nom_joueur> <faction>")
        else
            print("[SWTOR] Usage: swtor_setfaction <nom_joueur> <faction>")
        end
        return
    end
    local target = nil
    for _, p in ipairs(player.GetAll()) do
        if string.lower(p:Nick()):find(string.lower(targetName)) then
            target = p
            break
        end
    end
    if not target then
        if IsValid(ply) then ply:ChatPrint("[SWTOR] Joueur introuvable: " .. targetName) end
        return
    end
    local ok, err = SWTOR.SetFaction(target, factionKey)
    local msg = ok and ("Faction '" .. factionKey .. "' assignée à " .. target:Nick())
                   or ("Erreur: " .. tostring(err))
    if IsValid(ply) then ply:ChatPrint("[SWTOR] " .. msg) else print("[SWTOR] " .. msg) end
end)

-- !swtor_setgrade <joueur> <grade>
concommand.Add("swtor_setgrade", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then return end
    local targetName = args[1]
    local gradeNum   = tonumber(args[2])
    if not targetName or not gradeNum then return end
    for _, p in ipairs(player.GetAll()) do
        if string.lower(p:Nick()):find(string.lower(targetName)) then
            local ok, err = SWTOR.SetGrade(p, gradeNum, ply)
            local msg = ok and "Grade " .. gradeNum .. " assigné à " .. p:Nick()
                           or "Erreur: " .. tostring(err)
            if IsValid(ply) then ply:ChatPrint("[SWTOR] " .. msg) else print("[SWTOR] " .. msg) end
            return
        end
    end
end)

-- !swtor_promote <joueur>
concommand.Add("swtor_promote", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then return end
    local targetName = args[1]
    if not targetName then return end
    for _, p in ipairs(player.GetAll()) do
        if string.lower(p:Nick()):find(string.lower(targetName)) then
            local ok, err = SWTOR.PromotePlayer(p, ply)
            local msg = ok and p:Nick() .. " a été promu !" or "Erreur: " .. tostring(err)
            if IsValid(ply) then ply:ChatPrint("[SWTOR] " .. msg) else print("[SWTOR] " .. msg) end
            return
        end
    end
end)

-- !swtor_demote <joueur>
concommand.Add("swtor_demote", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then return end
    local targetName = args[1]
    if not targetName then return end
    for _, p in ipairs(player.GetAll()) do
        if string.lower(p:Nick()):find(string.lower(targetName)) then
            SWTOR.DemotePlayer(p, ply)
            if IsValid(ply) then ply:ChatPrint("[SWTOR] " .. p:Nick() .. " a été rétrogradé.") end
            return
        end
    end
end)

-- !swtor_givecredits <joueur> <montant>
concommand.Add("swtor_givecredits", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then return end
    local targetName = args[1]
    local amount     = tonumber(args[2])
    if not targetName or not amount then return end
    for _, p in ipairs(player.GetAll()) do
        if string.lower(p:Nick()):find(string.lower(targetName)) then
            SWTOR.GiveCredits(p, amount)
            if IsValid(ply) then
                ply:ChatPrint("[SWTOR] " .. amount .. " crédits donnés à " .. p:Nick())
            end
            return
        end
    end
end)

-- !swtor_teleport <joueur> <planète>
concommand.Add("swtor_teleport", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then return end
    local targetName = args[1]
    local planetKey  = args[2]
    if not targetName or not planetKey then return end
    for _, p in ipairs(player.GetAll()) do
        if string.lower(p:Nick()):find(string.lower(targetName)) then
            SWTOR.TeleportToPlanet(p, planetKey)
            if IsValid(ply) then
                ply:ChatPrint("[SWTOR] " .. p:Nick() .. " téléporté sur " .. planetKey)
            end
            return
        end
    end
end)

-- !swtor_info <joueur>
concommand.Add("swtor_info", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then return end
    local targetName = args[1]
    local printFn = IsValid(ply) and function(s) ply:ChatPrint(s) end or print
    if not targetName then
        -- Lister tous les joueurs
        printFn("=== SW:TOR - Joueurs connectés ===")
        for _, p in ipairs(player.GetAll()) do
            local faction = p.swtor_faction or "Aucune"
            local grade   = p.swtor_grade   or 0
            local credits = p.swtor_credits or 0
            printFn(string.format("  %s | Faction: %s | Grade: %d | Crédits: %d",
                p:Nick(), faction, grade, credits))
        end
        return
    end
    for _, p in ipairs(player.GetAll()) do
        if string.lower(p:Nick()):find(string.lower(targetName)) then
            printFn("=== SW:TOR Info: " .. p:Nick() .. " ===")
            printFn("SteamID  : " .. p:SteamID())
            printFn("Faction  : " .. (p.swtor_faction  or "Aucune"))
            printFn("Grade    : " .. (p.swtor_grade    or 0))
            printFn("XP       : " .. (p.swtor_xp       or 0))
            printFn("Crédits  : " .. (p.swtor_credits  or 0))
            printFn("Planète  : " .. (p.swtor_planet   or "Aucune"))
            printFn("Kills    : " .. (p.swtor_kills    or 0))
            printFn("Deaths   : " .. (p.swtor_deaths   or 0))
            printFn("Playtime : " .. math.floor((p.swtor_playtime or 0) / 60) .. " min")
            return
        end
    end
    printFn("[SWTOR] Joueur introuvable: " .. targetName)
end)

-- !swtor_listplanets
concommand.Add("swtor_listplanets", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then return end
    local printFn = IsValid(ply) and function(s) ply:ChatPrint(s) end or print
    printFn("=== SW:TOR - Planètes disponibles ===")
    for key, planet in pairs(SWTOR.Planets) do
        printFn(string.format("  %s | %s | Faction: %s", key, planet.name, planet.faction))
    end
end)

-- !swtor_listfactions
concommand.Add("swtor_listfactions", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then return end
    local printFn = IsValid(ply) and function(s) ply:ChatPrint(s) end or print
    printFn("=== SW:TOR - Factions ===")
    for key, faction in pairs(SWTOR.Factions) do
        local grades = SWTOR.Grades[key]
        printFn(string.format("  %s | %s | %d grades", key, faction.name, grades and #grades or 0))
    end
end)

-- !swtor_resetplayer <joueur>  (remet à zéro)
concommand.Add("swtor_resetplayer", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then return end
    local targetName = args[1]
    if not targetName then return end
    for _, p in ipairs(player.GetAll()) do
        if string.lower(p:Nick()):find(string.lower(targetName)) then
            p.swtor_faction  = ""
            p.swtor_grade    = 1
            p.swtor_xp       = 0
            p.swtor_credits  = 500
            p.swtor_planet   = ""
            p.swtor_kills    = 0
            p.swtor_deaths   = 0
            SWTOR.SavePlayer(p)
            SWTOR.SyncPlayerData(p)
            SWTOR.Notify(p, "Votre profil SW:TOR a été réinitialisé.", "warning")
            if IsValid(ply) then ply:ChatPrint("[SWTOR] " .. p:Nick() .. " réinitialisé.") end
            return
        end
    end
end)

-- ============================================================
--  CHAT COMMANDS (! prefix en jeu)
-- ============================================================
hook.Add("PlayerSay", "SWTOR_ChatCommands", function(ply, text)
    local cmd = string.lower(text)

    if cmd == "!myinfo" or cmd == "!profil" then
        local faction   = ply.swtor_faction or ""
        local gradeInfo = SWTOR.GetGrade(faction, ply.swtor_grade or 1)
        ply:ChatPrint("=== Votre profil SW:TOR ===")
        ply:ChatPrint("Faction  : " .. (SWTOR.Factions[faction] and SWTOR.Factions[faction].name or "Aucune"))
        ply:ChatPrint("Grade    : " .. (gradeInfo and gradeInfo.name or "N/A"))
        ply:ChatPrint("XP       : " .. (ply.swtor_xp or 0))
        ply:ChatPrint("Crédits  : " .. (ply.swtor_credits or 0))
        ply:ChatPrint("Planète  : " .. (ply.swtor_planet or "Aucune"))
        return ""  -- ne pas afficher le message dans le chat
    end

    if cmd == "!planets" or cmd == "!planetes" then
        ply:ChatPrint("=== Planètes SW:TOR ===")
        for key, planet in pairs(SWTOR.Planets) do
            ply:ChatPrint("  " .. planet.name .. " (" .. key .. ") - " .. planet.faction)
        end
        return ""
    end

    -- Chat factionnel: /empire message | /republique message | /mando message
    for factionKey, faction in pairs(SWTOR.Factions) do
        local prefix = "/" .. factionKey .. " "
        if string.sub(cmd, 1, #prefix) == prefix then
            local message = string.sub(text, #prefix + 1)
            if ply.swtor_faction ~= factionKey then
                ply:ChatPrint("[SWTOR] Vous n'êtes pas dans cette faction.")
                return ""
            end
            -- Envoyer le message seulement aux membres de la faction
            for _, p in ipairs(player.GetAll()) do
                if p.swtor_faction == factionKey then
                    p:ChatPrint(faction.chat_prefix .. " " .. ply:Nick() .. ": " .. message)
                end
            end
            return ""
        end
    end
end)

print("[SW:TOR RP] Commandes Admin chargées ✓")
print("[SW:TOR RP] Commandes disponibles:")
print("  swtor_setfaction <joueur> <faction>")
print("  swtor_setgrade   <joueur> <grade>")
print("  swtor_promote    <joueur>")
print("  swtor_demote     <joueur>")
print("  swtor_givecredits <joueur> <montant>")
print("  swtor_teleport   <joueur> <planète>")
print("  swtor_info       [joueur]")
print("  swtor_listplanets")
print("  swtor_listfactions")
print("  swtor_resetplayer <joueur>")