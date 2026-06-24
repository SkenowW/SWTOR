-- ============================================================
--  SW:TOR RP — FACTIONS, GRADES & STATS COMPLÈTES v3
--  lua/autorun/sh_swtor_factions.lua
--  Grades promouvables : Modérateurs (rangs de base + voies)
--  Grades admin only   : Haut Commandement + Corps Empereur + Légendes Jedi
-- ============================================================

SWTOR = SWTOR or {}
SWTOR.Factions = {}
SWTOR.Grades   = {}

-- ============================================================
--  PERMISSIONS PAR RANG
--  "mod"   = Modérateur peut promouvoir
--  "admin" = Admin uniquement
-- ============================================================

-- ============================================================
--  FACTION : EMPIRE SITH
-- ============================================================
SWTOR.Factions["empire"] = {
    name        = "Empire Sith",
    shortname   = "EMPIRE",
    color       = Color(180, 20, 20),
    description = "L'Empire Sith, gouverné par l'Empereur, repose sur la Force Obscure et la domination absolue.",
    planet_home = "korriban",
    planet_sec  = "dromund_kaas",
    chat_prefix = "[EMPIRE]",
    chat_color  = Color(220, 50, 50),
}

SWTOR.Grades["empire"] = {

    -- ── GRADES DE BASE (Modérateurs) ───────────────────────
    { rank=1,  name="Novice",
      hp=250,   armor=0,     force=50,   speed=70,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=50,  promo_req="mod",
      models={"models/swtor/sith/novice_m.mdl","models/swtor/sith/novice_f.mdl"} },

    { rank=2,  name="Acolyte",
      hp=360,   armor=0,     force=70,   speed=80,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=100, promo_req="mod",
      models={"models/swtor/sith/acolyte_m.mdl","models/swtor/sith/acolyte_f.mdl"} },

    { rank=3,  name="Inquisiteur",
      hp=410,   armor=0,     force=80,   speed=110,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=150, promo_req="mod",
      models={"models/swtor/sith/inquisitor_m.mdl","models/swtor/sith/inquisitor_f.mdl"} },

    { rank=4,  name="Guerrier Sith",
      hp=470,   armor=80,    force=80,   speed=100,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=200, promo_req="mod",
      models={"models/swtor/sith/warrior_m.mdl","models/swtor/sith/warrior_f.mdl"} },

    -- ── VOIE DU RAVAGEUR — sabre simple, agressif (Modérateurs) ──
    { rank=5,  name="Ravageur",
      hp=1100,  armor=200,   force=110,  speed=120,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=300, promo_req="mod", voie="ravageur",
      models={"models/swtor/sith/juggernaut_m.mdl","models/swtor/sith/juggernaut_f.mdl"} },

    { rank=6,  name="Grand Ravageur",
      hp=1400,  armor=200,   force=110,  speed=120,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=400, promo_req="mod", voie="ravageur",
      models={"models/swtor/sith/juggernaut_m.mdl","models/swtor/sith/juggernaut_f.mdl"} },

    { rank=7,  name="Maître des Ravageurs",
      hp=1700,  armor=300,   force=120,  speed=120,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=500, promo_req="mod", voie="ravageur",
      models={"models/swtor/sith/juggernaut_master_m.mdl","models/swtor/sith/juggernaut_master_f.mdl"} },

    -- ── VOIE DU MARAUDEUR — double sabre, rapide (Modérateurs) ──
    { rank=8,  name="Maraudeur",
      hp=1000,  armor=100,   force=130,  speed=140,
      weapon="swtor_lightsaber_dual", weapon_style="dual",
      salary=300, promo_req="mod", voie="maraudeur",
      models={"models/swtor/sith/marauder_m.mdl","models/swtor/sith/marauder_f.mdl"} },

    { rank=9,  name="Grand Maraudeur",
      hp=1100,  armor=100,   force=130,  speed=140,
      weapon="swtor_lightsaber_dual", weapon_style="dual",
      salary=400, promo_req="mod", voie="maraudeur",
      models={"models/swtor/sith/marauder_m.mdl","models/swtor/sith/marauder_f.mdl"} },

    { rank=10, name="Maître des Maraudeurs",
      hp=1200,  armor=200,   force=130,  speed=140,
      weapon="swtor_lightsaber_dual", weapon_style="dual",
      salary=500, promo_req="mod", voie="maraudeur",
      models={"models/swtor/sith/marauder_master_m.mdl","models/swtor/sith/marauder_master_f.mdl"} },

    -- ── VOIE DU SORCIER — sabre simple, Force distance (Modérateurs) ──
    { rank=11, name="Sorcier",
      hp=900,   armor=0,     force=130,  speed=140,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=300, promo_req="mod", voie="sorcier",
      models={"models/swtor/sith/sorcerer_m.mdl","models/swtor/sith/sorcerer_f.mdl"} },

    { rank=12, name="Grand Sorcier",
      hp=1100,  armor=0,     force=130,  speed=140,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=400, promo_req="mod", voie="sorcier",
      models={"models/swtor/sith/sorcerer_m.mdl","models/swtor/sith/sorcerer_f.mdl"} },

    { rank=13, name="Maître des Sorciers",
      hp=1300,  armor=0,     force=130,  speed=140,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=500, promo_req="mod", voie="sorcier",
      models={"models/swtor/sith/sorcerer_master_m.mdl","models/swtor/sith/sorcerer_master_f.mdl"} },

    -- ── VOIE DE L'ASSASSIN — double lame, furtif (Modérateurs) ──
    { rank=14, name="Assassin",
      hp=700,   armor=100,   force=160,  speed=200,
      weapon="swtor_lightsaber_double", weapon_style="double",
      salary=300, promo_req="mod", voie="assassin",
      models={"models/swtor/sith/assassin_m.mdl","models/swtor/sith/assassin_f.mdl"} },

    { rank=15, name="Grand Assassin",
      hp=900,   armor=100,   force=160,  speed=200,
      weapon="swtor_lightsaber_double", weapon_style="double",
      salary=400, promo_req="mod", voie="assassin",
      models={"models/swtor/sith/assassin_m.mdl","models/swtor/sith/assassin_f.mdl"} },

    { rank=16, name="Maître des Assassins",
      hp=1100,  armor=100,   force=160,  speed=200,
      weapon="swtor_lightsaber_double", weapon_style="double",
      salary=500, promo_req="mod", voie="assassin",
      models={"models/swtor/sith/assassin_master_m.mdl","models/swtor/sith/assassin_master_f.mdl"} },

    -- ── HAUT COMMANDEMENT SITH (Admin uniquement) ──────────
    { rank=17, name="Seigneur Inquisiteur",
      hp=2000,  armor=200,   force=200,  speed=200,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=1000, promo_req="admin",
      models={"models/swtor/sith/lord_inquisitor_m.mdl","models/swtor/sith/lord_inquisitor_f.mdl"} },

    { rank=18, name="Seigneur Guerrier",
      hp=2300,  armor=300,   force=200,  speed=190,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=1000, promo_req="admin",
      models={"models/swtor/sith/lord_warrior_m.mdl","models/swtor/sith/lord_warrior_f.mdl"} },

    { rank=19, name="Darth Inquisiteur",
      hp=2300,  armor=200,   force=200,  speed=200,
      weapon="swtor_lightsaber_double", weapon_style="double",
      salary=1500, promo_req="admin",
      models={"models/swtor/sith/darth_inquisitor_m.mdl","models/swtor/sith/darth_inquisitor_f.mdl"} },

    { rank=20, name="Darth Guerrier",
      hp=2600,  armor=400,   force=200,  speed=190,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=1500, promo_req="admin",
      models={"models/swtor/sith/darth_warrior_m.mdl","models/swtor/sith/darth_warrior_f.mdl"} },

    -- ── CORPS DE L'EMPEREUR (Admin uniquement + auras exclusives) ──
    { rank=21, name="Furie de l'Empereur",
      hp=3500,  armor=500,   force=200,  speed=220,
      weapon="swtor_lightsaber_dual", weapon_style="dual",
      salary=3000, promo_req="admin",
      exclusive_aura="aura_furie",
      models={"models/swtor/emperor/furie_m.mdl","models/swtor/emperor/furie_f.mdl"} },

    { rank=22, name="Main de l'Empereur",
      hp=2700,  armor=400,   force=230,  speed=220,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=3000, promo_req="admin",
      exclusive_aura="aura_mains",
      models={"models/swtor/emperor/hand_m.mdl","models/swtor/emperor/hand_f.mdl"} },

    { rank=23, name="Voix de l'Empereur",
      hp=8500,  armor=1500,  force=350,  speed=260,
      weapon="swtor_lightsaber_double", weapon_style="double",
      salary=5000, promo_req="admin",
      exclusive_aura="aura_mains",
      models={"models/swtor/emperor/voice_m.mdl","models/swtor/emperor/voice_f.mdl"} },

    { rank=24, name="Empereur",
      hp=75000, armor=25000, force=1500, speed=400,
      weapon="swtor_lightsaber_double", weapon_style="double",
      salary=10000, promo_req="admin",
      exclusive_aura="aura_empereur",
      models={"models/swtor/emperor/emperor_m.mdl"} },
}

-- ============================================================
--  FACTION : ORDRE JEDI / REPUBLIQUE
-- ============================================================
SWTOR.Factions["republique"] = {
    name        = "Ordre Jedi",
    shortname   = "JEDI",
    color       = Color(30, 100, 200),
    description = "L'Ordre Jedi, gardien de la paix et de la lumière, protège la République Galactique depuis des millénaires.",
    planet_home = "coruscant",
    planet_sec  = nil,
    chat_prefix = "[JEDI]",
    chat_color  = Color(80, 160, 255),
}

SWTOR.Grades["republique"] = {

    -- ── GRADES DE BASE (Modérateurs) ───────────────────────
    { rank=1,  name="Novice",
      hp=250,   armor=0,     force=50,   speed=70,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=50,  promo_req="mod",
      models={"models/swtor/jedi/youngling_m.mdl","models/swtor/jedi/youngling_f.mdl"} },

    { rank=2,  name="Apprenti",             -- Acolyte
      hp=360,   armor=0,     force=70,   speed=80,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=100, promo_req="mod",
      models={"models/swtor/jedi/padawan_m.mdl","models/swtor/jedi/padawan_f.mdl"} },

    { rank=3,  name="Consulaire",           -- Inquisiteur
      hp=410,   armor=0,     force=80,   speed=110,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=150, promo_req="mod",
      models={"models/swtor/jedi/consular_m.mdl","models/swtor/jedi/consular_f.mdl"} },

    { rank=4,  name="Chevalier",            -- Guerrier
      hp=470,   armor=80,    force=80,   speed=100,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=200, promo_req="mod",
      models={"models/swtor/jedi/knight_m.mdl","models/swtor/jedi/knight_f.mdl"} },

    -- ── VOIE DU GARDIEN — sabre simple, agressif (Modérateurs) ──
    { rank=5,  name="Gardien",              -- Ravageur
      hp=1100,  armor=200,   force=110,  speed=120,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=300, promo_req="mod", voie="gardien",
      models={"models/swtor/jedi/guardian_m.mdl","models/swtor/jedi/guardian_f.mdl"} },

    { rank=6,  name="Grand Gardien",
      hp=1400,  armor=200,   force=110,  speed=120,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=400, promo_req="mod", voie="gardien",
      models={"models/swtor/jedi/guardian_m.mdl","models/swtor/jedi/guardian_f.mdl"} },

    { rank=7,  name="Maître des Gardiens",
      hp=1700,  armor=300,   force=120,  speed=120,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=500, promo_req="mod", voie="gardien",
      models={"models/swtor/jedi/guardian_master_m.mdl","models/swtor/jedi/guardian_master_f.mdl"} },

    -- ── VOIE DE LA SENTINELLE — double sabre (Modérateurs) ──
    { rank=8,  name="Sentinelle",           -- Maraudeur
      hp=1000,  armor=100,   force=130,  speed=140,
      weapon="swtor_lightsaber_dual", weapon_style="dual",
      salary=300, promo_req="mod", voie="sentinelle",
      models={"models/swtor/jedi/sentinel_m.mdl","models/swtor/jedi/sentinel_f.mdl"} },

    { rank=9,  name="Grande Sentinelle",
      hp=1100,  armor=100,   force=130,  speed=140,
      weapon="swtor_lightsaber_dual", weapon_style="dual",
      salary=400, promo_req="mod", voie="sentinelle",
      models={"models/swtor/jedi/sentinel_m.mdl","models/swtor/jedi/sentinel_f.mdl"} },

    { rank=10, name="Maître des Sentinelles",
      hp=1200,  armor=200,   force=130,  speed=140,
      weapon="swtor_lightsaber_dual", weapon_style="dual",
      salary=500, promo_req="mod", voie="sentinelle",
      models={"models/swtor/jedi/sentinel_master_m.mdl","models/swtor/jedi/sentinel_master_f.mdl"} },

    -- ── VOIE DE L'ÉRUDIT — sabre simple, Force distance (Modérateurs) ──
    { rank=11, name="Érudit",              -- Sorcier
      hp=900,   armor=0,     force=130,  speed=140,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=300, promo_req="mod", voie="erudit",
      models={"models/swtor/jedi/sage_m.mdl","models/swtor/jedi/sage_f.mdl"} },

    { rank=12, name="Grand Érudit",
      hp=1100,  armor=0,     force=130,  speed=140,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=400, promo_req="mod", voie="erudit",
      models={"models/swtor/jedi/sage_m.mdl","models/swtor/jedi/sage_f.mdl"} },

    { rank=13, name="Maître des Érudits",
      hp=1300,  armor=0,     force=130,  speed=140,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=500, promo_req="mod", voie="erudit",
      models={"models/swtor/jedi/sage_master_m.mdl","models/swtor/jedi/sage_master_f.mdl"} },

    -- ── VOIE DE L'OMBRE — double lame, furtif (Modérateurs) ──
    { rank=14, name="Ombre",               -- Assassin
      hp=700,   armor=100,   force=160,  speed=200,
      weapon="swtor_lightsaber_double", weapon_style="double",
      salary=300, promo_req="mod", voie="ombre",
      models={"models/swtor/jedi/shadow_m.mdl","models/swtor/jedi/shadow_f.mdl"} },

    { rank=15, name="Grande Ombre",
      hp=900,   armor=100,   force=160,  speed=200,
      weapon="swtor_lightsaber_double", weapon_style="double",
      salary=400, promo_req="mod", voie="ombre",
      models={"models/swtor/jedi/shadow_m.mdl","models/swtor/jedi/shadow_f.mdl"} },

    { rank=16, name="Maître des Ombres",
      hp=1100,  armor=100,   force=160,  speed=200,
      weapon="swtor_lightsaber_double", weapon_style="double",
      salary=500, promo_req="mod", voie="ombre",
      models={"models/swtor/jedi/shadow_master_m.mdl","models/swtor/jedi/shadow_master_f.mdl"} },

    -- ── HAUT COMMANDEMENT JEDI (Admin uniquement) ──────────
    { rank=17, name="Maître Jedi Consulaire",      -- Seigneur Inquisiteur
      hp=2000,  armor=200,   force=200,  speed=200,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=1000, promo_req="admin",
      models={"models/swtor/jedi/master_consular_m.mdl","models/swtor/jedi/master_consular_f.mdl"} },

    { rank=18, name="Maître Jedi Guerrier",         -- Seigneur Guerrier
      hp=2300,  armor=300,   force=200,  speed=190,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=1000, promo_req="admin",
      models={"models/swtor/jedi/master_warrior_m.mdl","models/swtor/jedi/master_warrior_f.mdl"} },

    { rank=19, name="Grand Maître Jedi Consulaire", -- Darth Inquisiteur
      hp=2300,  armor=200,   force=200,  speed=200,
      weapon="swtor_lightsaber_double", weapon_style="double",
      salary=1500, promo_req="admin",
      models={"models/swtor/jedi/grandmaster_consular_m.mdl","models/swtor/jedi/grandmaster_consular_f.mdl"} },

    { rank=20, name="Grand Maître Jedi Guerrier",   -- Darth Guerrier
      hp=2600,  armor=400,   force=200,  speed=190,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=1500, promo_req="admin",
      models={"models/swtor/jedi/grandmaster_warrior_m.mdl","models/swtor/jedi/grandmaster_warrior_f.mdl"} },

    -- ── CONSEIL DES LÉGENDES JEDI (Admin uniquement + auras) ──
    { rank=21, name="Conseiller Légende",   -- Main de l'Empereur
      hp=2700,  armor=400,   force=230,  speed=220,
      weapon="swtor_lightsaber", weapon_style="single",
      salary=3000, promo_req="admin",
      exclusive_aura="aura_legende_jedi",
      models={"models/swtor/jedi/legend_consular_m.mdl","models/swtor/jedi/legend_consular_f.mdl"} },

    { rank=22, name="Furie Légendaire Jedi", -- Furie de l'Empereur
      hp=3500,  armor=500,   force=200,  speed=220,
      weapon="swtor_lightsaber_dual", weapon_style="dual",
      salary=3000, promo_req="admin",
      exclusive_aura="aura_legende_jedi",
      models={"models/swtor/jedi/legend_sentinel_m.mdl","models/swtor/jedi/legend_sentinel_f.mdl"} },

    { rank=23, name="Voix de la Force",      -- Voix de l'Empereur
      hp=8500,  armor=1500,  force=350,  speed=260,
      weapon="swtor_lightsaber_double", weapon_style="double",
      salary=5000, promo_req="admin",
      exclusive_aura="aura_legende_jedi",
      models={"models/swtor/jedi/legend_voice_m.mdl","models/swtor/jedi/legend_voice_f.mdl"} },

    { rank=24, name="Légende Jedi",          -- Empereur
      hp=75000, armor=25000, force=1500, speed=400,
      weapon="swtor_lightsaber_double", weapon_style="double",
      salary=10000, promo_req="admin",
      exclusive_aura="aura_legende_jedi",
      models={"models/swtor/jedi/legend_jedi_m.mdl"} },
}

-- ============================================================
--  FACTION : MANDALORIEN (inchangée)
-- ============================================================
SWTOR.Factions["mandalorien"] = {
    name        = "Clan Mandalorien",
    shortname   = "MANDO",
    color       = Color(180, 140, 20),
    description = "Guerriers nomades liés par le code Resol'nare. Honneur, combat et loyauté au clan avant tout.",
    planet_home = "mandalore",
    planet_sec  = nil,
    chat_prefix = "[MANDO]",
    chat_color  = Color(220, 180, 40),
}

SWTOR.Grades["mandalorien"] = {
    { rank=1, name="Verd (Soldat)",       hp=400,  armor=50,  force=60,  speed=130, salary=100,
      weapon="swtor_blaster_dual", weapon_style="dual", promo_req="mod",
      models={"models/swtor/mando/verd_m.mdl","models/swtor/mando/verd_f.mdl"} },
    { rank=2, name="Mando'ad",            hp=600,  armor=80,  force=70,  speed=140, salary=150,
      weapon="swtor_blaster_dual", weapon_style="dual", promo_req="mod",
      models={"models/swtor/mando/mandoad_m.mdl"} },
    { rank=3, name="Alor'ad (Capitaine)", hp=900,  armor=120, force=80,  speed=150, salary=250,
      weapon="swtor_vibroblade",   weapon_style="vibro", promo_req="mod",
      models={"models/swtor/mando/captain_m.mdl"} },
    { rank=4, name="Alor (Chef de Clan)",hp=1400, armor=200, force=100, speed=160, salary=500,
      weapon="swtor_vibroblade",   weapon_style="vibro", promo_req="admin",
      models={"models/swtor/mando/clan_chief_m.mdl"} },
    { rank=5, name="Mand'alor",          hp=3000, armor=600, force=200, speed=200, salary=2000,
      weapon="swtor_vibroblade",   weapon_style="vibro", promo_req="admin",
      models={"models/swtor/mando/mandalor_m.mdl"} },
}

-- ============================================================
--  HELPERS
-- ============================================================

function SWTOR.GetGrade(factionKey, rankIndex)
    local grades = SWTOR.Grades[factionKey]
    if not grades then return nil end
    return grades[rankIndex]
end

function SWTOR.GetMaxGrade(factionKey)
    local grades = SWTOR.Grades[factionKey]
    return grades and #grades or 0
end

function SWTOR.GetNextGrade(factionKey, rankIndex)
    return SWTOR.GetGrade(factionKey, rankIndex + 1)
end

-- Vérifie si un joueur peut promouvoir selon promo_req
function SWTOR.CanPromote(promoter, factionKey, targetRank)
    local grade = SWTOR.GetGrade(factionKey, targetRank)
    if not grade then return false end
    if grade.promo_req == "admin" then
        return promoter:IsAdmin()
    end
    -- "mod" = IsSuperAdmin ou custom perm ULX
    return promoter:IsAdmin() or promoter:IsSuperAdmin() or
           (ULib and ULib.ucl and ULib.ucl.authedUsers and
            ULib.ucl.authedUsers[promoter:SteamID()] ~= nil)
end

-- Retourner tous les grades d'une voie
function SWTOR.GetVoieGrades(factionKey, voie)
    local grades = SWTOR.Grades[factionKey]
    if not grades then return {} end
    local result = {}
    for _, g in ipairs(grades) do
        if g.voie == voie then table.insert(result, g) end
    end
    return result
end

-- Appliquer les stats d'un grade directement
function SWTOR.ApplyGradeStats(ply)
    if not IsValid(ply) then return end
    local faction = ply.swtor_faction or ""
    local grade   = SWTOR.GetGrade(faction, ply.swtor_grade or 1)
    if not grade then return end

    -- HP
    local maxHP = math.min(grade.hp, 75000)
    ply:SetMaxHealth(maxHP)
    ply:SetHealth(maxHP)

    -- Armure (GMod cap = 100, on stocke la vraie valeur en NWInt)
    local realArmor = grade.armor or 0
    ply:SetNWInt("swtor_real_armor", realArmor)
    ply:SetArmor(math.min(realArmor, 100))  -- UI seulement

    -- Vitesse
    local spd = grade.speed or 200
    ply:SetWalkSpeed(spd * 0.55)
    ply:SetRunSpeed(spd)
    ply:SetCrouchedWalkSpeed(0.35)

    -- Arme de grade automatique
    if grade.weapon then
        -- Retirer les anciennes armes de sabre
        for _, wclass in ipairs({"swtor_lightsaber","swtor_lightsaber_dual",
                                  "swtor_lightsaber_double","swtor_vibroblade"}) do
            local w = ply:GetWeapon(wclass)
            if IsValid(w) then ply:StripWeapon(wclass) end
        end
        ply:Give(grade.weapon)
        ply:SelectWeapon(grade.weapon)
    end

    -- Aura exclusive au grade
    if grade.exclusive_aura and SWTOR.BroadcastAura then
        ply.swtor_aura = grade.exclusive_aura
        SWTOR.BroadcastAura(ply, grade.exclusive_aura)
    end
end

-- Stats Force/Speed pour les formules de combat
function SWTOR.GetCombatStats(ply)
    local faction = ply.swtor_faction or ""
    local grade   = SWTOR.GetGrade(faction, ply.swtor_grade or 1)
    if not grade then return 50, 100, 50 end
    return grade.force or 50, grade.speed or 100, grade.hp or 250
end

-- Nombre de grades Sith : 24 | Jedi : 24 | Mando : 5
local total = 0
for _, grades in pairs(SWTOR.Grades) do total = total + #grades end
print("[SW:TOR RP] Factions & Grades chargés ✓ (" .. total .. " grades au total)")
print("  Empire: " .. #SWTOR.Grades["empire"] .. " grades")
print("  Jedi:   " .. #SWTOR.Grades["republique"] .. " grades")
print("  Mando:  " .. #SWTOR.Grades["mandalorien"] .. " grades")
