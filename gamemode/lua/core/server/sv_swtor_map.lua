-- ============================================================
--  SW:TOR RP - CONFIGURATION MAP & TRIGGERS PLANÈTES
--  Fichier: lua/autorun/server/sv_swtor_map.lua
--  Coller dans: garrysmod/lua/autorun/server/
--
--  Ce fichier gère:
--  1) Les portails/triggers de voyage inter-planètes
--  2) Les zones de faction (accès restreint)
--  3) Les spawns conditionnels
--  4) L'ambiance sonore par zone
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_TeleportPlanet")
util.AddNetworkString("SWTOR_ZoneEnter")
util.AddNetworkString("SWTOR_PlayAmbient")

-- ============================================================
--  PORTAILS DE VOYAGE (Triggers box sur la map)
--  Ajuster les Vector() selon votre map réelle
-- ============================================================

SWTOR.TravelPortals = {
    -- Depuis n'importe où → Hangar central (zone neutre)
    {
        label        = "Hangar Central → Korriban",
        trigger_mins = Vector(-50, -50, 0),
        trigger_maxs = Vector(50, 50, 200),
        dest_planet  = "korriban",
        faction_req  = "empire",    -- nil = tout le monde peut l'utiliser
        message      = "Embarquement pour Korriban...",
    },
    {
        label        = "Hangar Central → Dromund Kaas",
        trigger_mins = Vector(100, -50, 0),
        trigger_maxs = Vector(200, 50, 200),
        dest_planet  = "dromund_kaas",
        faction_req  = "empire",
        message      = "Embarquement pour Dromund Kaas...",
    },
    {
        label        = "Hangar Central → Coruscant",
        trigger_mins = Vector(-200, -50, 0),
        trigger_maxs = Vector(-100, 50, 200),
        dest_planet  = "coruscant",
        faction_req  = "republique",
        message      = "Embarquement pour Coruscant...",
    },
    {
        label        = "Hangar Central → Mandalore",
        trigger_mins = Vector(-50, 100, 0),
        trigger_maxs = Vector(50, 200, 200),
        dest_planet  = "mandalore",
        faction_req  = "mandalorien",
        message      = "Embarquement pour Mandalore...",
    },
    {
        label        = "Hangar Central → Nar Shaddaa",
        trigger_mins = Vector(-50, -200, 0),
        trigger_maxs = Vector(50, -100, 200),
        dest_planet  = "nar_shaddaa",
        faction_req  = nil,         -- Accès libre
        message      = "Embarquement pour Nar Shaddaa...",
    },
}

-- ============================================================
--  ZONES DE FACTIONS (accès interdit aux autres factions)
-- ============================================================

SWTOR.FactionZones = {
    {
        label        = "Académie Sith (Korriban)",
        mins         = Vector(-2000, 0, 0),
        maxs         = Vector(-500, 1500, 512),
        faction_req  = "empire",
        warn_msg     = "Vous n'êtes pas autorisé dans l'Académie Sith !",
        push_out     = true,    -- Repousser si non autorisé
    },
    {
        label        = "Temple Jedi (Coruscant)",
        mins         = Vector(-500, -500, 0),
        maxs         = Vector(500, 500, 600),
        faction_req  = "republique",
        warn_msg     = "Le Temple Jedi est réservé à la République !",
        push_out     = true,
    },
    {
        label        = "Cité Impériale (Dromund Kaas)",
        mins         = Vector(0, 0, 0),
        maxs         = Vector(2000, 2000, 512),
        faction_req  = "empire",
        warn_msg     = "Entrée interdite aux ennemis de l'Empire !",
        push_out     = false,   -- Avertissement seulement
    },
}

-- ============================================================
--  TICK: Vérification des zones et portails
-- ============================================================

local cooldowns = {}  -- Anti-spam téléportation

timer.Create("SWTOR_ZoneCheck", 0.2, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or not ply:Alive() then continue end
        local pos = ply:GetPos()
        local sid = ply:SteamID()

        -- ─── Vérification portails ───
        if not cooldowns[sid] or cooldowns[sid] < CurTime() then
            for _, portal in ipairs(SWTOR.TravelPortals) do
                if pos:WithinAABox(portal.trigger_mins, portal.trigger_maxs) then
                    -- Vérifier la faction requise
                    if portal.faction_req and ply.swtor_faction ~= portal.faction_req then
                        SWTOR.Notify(ply, "Accès refusé. Faction: " .. portal.faction_req .. " requise.", "error")
                        cooldowns[sid] = CurTime() + 3
                    else
                        SWTOR.Notify(ply, portal.message, "info")
                        timer.Simple(2, function()
                            if IsValid(ply) then
                                SWTOR.TeleportToPlanet(ply, portal.dest_planet)
                            end
                        end)
                        cooldowns[sid] = CurTime() + 10
                    end
                    break
                end
            end
        end

        -- ─── Vérification zones de faction ───
        for _, zone in ipairs(SWTOR.FactionZones) do
            if pos:WithinAABox(zone.mins, zone.maxs) then
                if zone.faction_req and ply.swtor_faction ~= zone.faction_req then
                    local zoneKey = sid .. "_" .. zone.label
                    if not cooldowns[zoneKey] or cooldowns[zoneKey] < CurTime() then
                        SWTOR.Notify(ply, zone.warn_msg, "warning")
                        cooldowns[zoneKey] = CurTime() + 8

                        if zone.push_out then
                            -- Repousser le joueur hors de la zone
                            local pushDir = (pos - (zone.mins + zone.maxs) * 0.5):GetNormalized()
                            ply:SetVelocity(pushDir * 400)
                        end
                    end
                end
                break
            end
        end
    end
end)

-- ============================================================
--  RÉCEPTION DEMANDE DE TÉLÉPORTATION CLIENT
-- ============================================================

net.Receive("SWTOR_TeleportPlanet", function(len, ply)
    local planetKey = net.ReadString()
    local planet    = SWTOR.Planets[planetKey]

    if not planet then
        SWTOR.Notify(ply, "Planète inconnue: " .. planetKey, "error")
        return
    end

    -- Vérifier accès
    local canAccess = (planet.faction == ply.swtor_faction)
        or (planet.faction == "neutre")
        or (planet.type == "neutral")
        or ply:IsAdmin()

    if not canAccess then
        SWTOR.Notify(ply, "Accès refusé à " .. planet.name .. ". Faction requise: " .. planet.faction, "error")
        return
    end

    SWTOR.TeleportToPlanet(ply, planetKey)
end)

-- ============================================================
--  SPAWN PAR FACTION AU RESPAWN
-- ============================================================

hook.Add("PlayerSpawn", "SWTOR_FactionSpawn", function(ply)
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end

        local faction = ply.swtor_faction or ""
        local planet  = ply.swtor_planet  or ""

        -- Si le joueur a une planète sauvegardée, spawner dessus
        if planet ~= "" and SWTOR.Planets[planet] then
            local spawnData = SWTOR.GetRandomSpawn(planet)
            if spawnData then
                ply:SetPos(spawnData.pos)
                ply:SetEyeAngles(spawnData.ang)
            end
        elseif faction ~= "" then
            -- Spawner sur la planète home de la faction
            local factionData = SWTOR.Factions[faction]
            if factionData and factionData.planet_home then
                local spawnData = SWTOR.GetRandomSpawn(factionData.planet_home)
                if spawnData then
                    ply:SetPos(spawnData.pos)
                    ply:SetEyeAngles(spawnData.ang)
                    ply.swtor_planet = factionData.planet_home
                end
            end
        end

        -- Restaurer le modèle
        if ply.swtor_model and ply.swtor_model ~= "" then
            ply:SetModel(ply.swtor_model)
        end
    end)
end)

-- ============================================================
--  ANNONCES DE CONNEXION (chat global)
-- ============================================================

hook.Add("PlayerInitialSpawn", "SWTOR_WelcomeAnnounce", function(ply)
    timer.Simple(3, function()
        if not IsValid(ply) then return end
        local faction   = ply.swtor_faction or ""
        local fData     = SWTOR.Factions[faction]
        local fName     = fData and fData.name or "Sans faction"
        local fColor    = fData and fData.color or Color(200,200,200)
        local gradeInfo = SWTOR.GetGrade(faction, ply.swtor_grade or 1)
        local gName     = gradeInfo and gradeInfo.name or "N/A"

        for _, p in ipairs(player.GetAll()) do
            p:ChatPrint("▶ " .. ply:Nick() .. " [" .. fName .. " — " .. gName .. "] vient de rejoindre la galaxie.")
        end
    end)
end)

print("[SW:TOR RP] Map & Zones chargés ✓")
print("  Portails: " .. #SWTOR.TravelPortals .. " | Zones: " .. #SWTOR.FactionZones)
