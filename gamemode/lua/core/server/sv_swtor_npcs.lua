-- ============================================================
--  SW:TOR RP — NPC GARDIENS PAR PLANÈTE
--  lua/autorun/server/sv_swtor_npcs.lua
-- ============================================================

if CLIENT then return end

-- ============================================================
--  DÉFINITION DES NPC PAR PLANÈTE
-- ============================================================
SWTOR.NPCDefs = {

    korriban = {
        { model = "models/swtor/sith/acolyte_m.mdl", class = "npc_combine_s",
          pos = Vector(-1100, 600, 64), ang = Angle(0,180,0),
          name = "Garde Sith",  faction = "empire", hp = 150, dmg_mult = 1.0 },
        { model = "models/swtor/sith/warrior_m.mdl",  class = "npc_combine_s",
          pos = Vector(-1300, 400, 64), ang = Angle(0,90,0),
          name = "Guerrier Sith", faction = "empire", hp = 200, dmg_mult = 1.2 },
        { model = "models/swtor/imperial/trooper.mdl", class = "npc_combine_s",
          pos = Vector(-900,  850, 64), ang = Angle(0,270,0),
          name = "Soldat Impérial", faction = "empire", hp = 100, dmg_mult = 0.8 },
    },

    dromund_kaas = {
        { model = "models/swtor/imperial/officer_m.mdl", class = "npc_combine_s",
          pos = Vector(600, 300, 64), ang = Angle(0,0,0),
          name = "Officier Impérial", faction = "empire", hp = 120, dmg_mult = 1.0 },
        { model = "models/swtor/imperial/trooper.mdl", class = "npc_combine_s",
          pos = Vector(900, 500, 64), ang = Angle(0,90,0),
          name = "Sentinelle Impériale", faction = "empire", hp = 100, dmg_mult = 0.8 },
    },

    coruscant = {
        { model = "models/swtor/jedi/knight_m.mdl", class = "npc_metropolice",
          pos = Vector(300, 100, 64), ang = Angle(0,270,0),
          name = "Chevalier Jedi", faction = "republique", hp = 200, dmg_mult = 1.0 },
        { model = "models/swtor/republic/trooper.mdl", class = "npc_metropolice",
          pos = Vector(100, 400, 64), ang = Angle(0,0,0),
          name = "Garde Républicain", faction = "republique", hp = 100, dmg_mult = 0.8 },
        { model = "models/swtor/jedi/guardian_m.mdl", class = "npc_metropolice",
          pos = Vector(-200, 100, 64), ang = Angle(0,180,0),
          name = "Garde du Temple", faction = "republique", hp = 180, dmg_mult = 1.1 },
    },

    mandalore = {
        { model = "models/swtor/mando/verd.mdl", class = "npc_combine_s",
          pos = Vector(-100, -300, 64), ang = Angle(0,45,0),
          name = "Guerrier Mandalorien", faction = "mandalorien", hp = 220, dmg_mult = 1.3 },
    },
}

-- ============================================================
--  SPAWN DES NPC
-- ============================================================
SWTOR.SpawnedNPCs = SWTOR.SpawnedNPCs or {}

local function SpawnPlanetNPCs(planetKey)
    local defs = SWTOR.NPCDefs[planetKey]
    if not defs then return end

    if SWTOR.SpawnedNPCs[planetKey] then
        for _, npc in ipairs(SWTOR.SpawnedNPCs[planetKey]) do
            if IsValid(npc) then npc:Remove() end
        end
    end
    SWTOR.SpawnedNPCs[planetKey] = {}

    for _, def in ipairs(defs) do
        local npc = ents.Create(def.class or "npc_combine_s")
        if not IsValid(npc) then continue end

        npc:SetPos(def.pos)
        npc:SetAngles(def.ang)
        npc:SetModel(def.model)
        npc:Spawn()
        npc:Activate()

        -- HP
        npc:SetMaxHealth(def.hp or 100)
        npc:SetHealth(def.hp   or 100)

        -- Métadonnées
        npc.swtor_faction  = def.faction
        npc.swtor_name     = def.name
        npc.swtor_planet   = planetKey
        npc.swtor_dmg_mult = def.dmg_mult or 1.0

        -- Hostilité envers factions ennemies
        npc:SetSaveValue("m_iMaxHealth", def.hp or 100)

        table.insert(SWTOR.SpawnedNPCs[planetKey], npc)
    end

    print("[SW:TOR] NPC spawnés sur " .. planetKey .. " (" .. #defs .. " entités)")
end

-- ============================================================
--  COMPORTEMENT NPC : N'attaque que les factions ennemies
-- ============================================================
hook.Add("OnNPCKilled", "SWTOR_NPCKilled", function(npc, attacker, inflictor)
    if not npc.swtor_planet then return end

    -- Respawn NPC après 60s
    local planetKey = npc.swtor_planet
    timer.Simple(60, function()
        SpawnPlanetNPCs(planetKey)
    end)

    -- XP pour le tueur
    if IsValid(attacker) and attacker:IsPlayer() then
        local xpGain = 50
        attacker.swtor_xp = (attacker.swtor_xp or 0) + xpGain
        SWTOR.Notify(attacker, "⚔ NPC éliminé: +" .. xpGain .. " XP", "success")
        SWTOR.SavePlayer(attacker)
        SWTOR.SyncPlayerData(attacker)
    end
end)

-- NPC attaque seulement les factions ennemies
hook.Add("PlayerShouldTakeDamage", "SWTOR_NPCFactionDamage", function(victim, attacker)
    if not attacker:IsNPC() or not attacker.swtor_faction then return end
    local victimFaction = victim.swtor_faction or ""

    -- Même faction = NPC ne blesse pas
    if attacker.swtor_faction == victimFaction then return false end

    -- Neutre = NPC n'attaque pas
    if victimFaction == "" then return false end

    return true
end)

-- ============================================================
--  SPAWN AU DÉMARRAGE
-- ============================================================
hook.Add("InitPostEntity", "SWTOR_SpawnAllNPCs", function()
    timer.Simple(3, function()
        for planetKey, _ in pairs(SWTOR.NPCDefs) do
            SpawnPlanetNPCs(planetKey)
        end
    end)
end)

concommand.Add("swtor_respawn_npcs", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then return end
    local planet = args[1]
    if planet then
        SpawnPlanetNPCs(planet)
    else
        for key in pairs(SWTOR.NPCDefs) do SpawnPlanetNPCs(key) end
    end
    if IsValid(ply) then ply:ChatPrint("[SWTOR] NPC respawnés.") end
end)

print("[SW:TOR] NPC Gardiens chargés ✓")
