-- ============================================================
--  SW:TOR RP — SYSTÈME DE 300 NIVEAUX
--  lua/autorun/sh_swtor_levels.lua
--  400h de jeu = niveau 300 | 4800s = 80min par niveau
-- ============================================================

SWTOR = SWTOR or {}
SWTOR.Levels = SWTOR.Levels or {}

SWTOR.Levels.MaxLevel        = 300
SWTOR.Levels.SecondsPerLevel = 4800  -- 80 minutes par niveau

function SWTOR.Levels.GetLevel(ply)
    local total = (ply.swtor_playtime or 0) + (ply.swtor_xp or 0)
    return math.Clamp(math.floor(total / SWTOR.Levels.SecondsPerLevel) + 1, 1, 300)
end

function SWTOR.Levels.GetProgress(ply)
    local total    = (ply.swtor_playtime or 0) + (ply.swtor_xp or 0)
    local level    = SWTOR.Levels.GetLevel(ply)
    local consumed = (level - 1) * SWTOR.Levels.SecondsPerLevel
    return math.Clamp((total - consumed) / SWTOR.Levels.SecondsPerLevel, 0, 1), level
end

function SWTOR.Levels.GetUnlockedOutfits(ply)
    local faction = ply.swtor_faction or ""
    local level   = SWTOR.Levels.GetLevel(ply)
    local list    = faction == "empire" and SWTOR.Levels.SithOutfits
                 or faction == "republique" and SWTOR.Levels.JediOutfits
                 or nil
    if not list then return {} end
    local unlocked = {}
    for _, outfit in ipairs(list) do
        if level >= outfit.lvl then table.insert(unlocked, outfit) end
    end
    return unlocked
end

-- Tenues Sith (résumé - niveaux clés)
SWTOR.Levels.SithOutfits = {
    { lvl=1,   name="Robes de Novice",               model="models/swtor/sith/novice_m.mdl" },
    { lvl=10,  name="Tunique de l'Acolyte",          model="models/swtor/sith/acolyte_m.mdl" },
    { lvl=20,  name="Robes de l'Apprenti",           model="models/swtor/sith/apprentice_m.mdl" },
    { lvl=35,  name="Robes du Sorcier Sith",         model="models/swtor/sith/sorcerer_m.mdl" },
    { lvl=51,  name="Armure du Guerrier Sith",       model="models/swtor/sith/warrior_m.mdl" },
    { lvl=65,  name="Armure du Maraudeur",           model="models/swtor/sith/marauder_m.mdl" },
    { lvl=81,  name="Armure du Ravageur",            model="models/swtor/sith/juggernaut_m.mdl" },
    { lvl=111, name="Tenue de l'Assassin Sith",      model="models/swtor/sith/assassin_m.mdl" },
    { lvl=150, name="Armure Noire Gravée",           model="models/swtor/sith/engraved_m.mdl" },
    { lvl=200, name="✦ Armure du Seigneur Sith",     model="models/swtor/sith/lord_m.mdl" },
    { lvl=210, name="Seigneur Guerrier Armure",      model="models/swtor/sith/lord_warrior_m.mdl" },
    { lvl=230, name="Darth Inquisiteur Robes",       model="models/swtor/sith/darth_inquisitor_m.mdl" },
    { lvl=235, name="Darth Guerrier Armure",         model="models/swtor/sith/darth_warrior_m.mdl" },
    { lvl=250, name="✦ Tenue de la Furie",           model="models/swtor/emperor/furie_m.mdl" },
    { lvl=270, name="Armure de la Voix",             model="models/swtor/emperor/voice_m.mdl" },
    { lvl=290, name="Robes du Conseil Noir",         model="models/swtor/sith/council_m.mdl" },
    { lvl=300, name="✦ Armure de l'Élu des Ténèbres",model="models/swtor/sith/chosen_m.mdl" },
}

-- Tenues Jedi (résumé)
SWTOR.Levels.JediOutfits = {
    { lvl=1,   name="Robes de Novice Jedi",          model="models/swtor/jedi/youngling_m.mdl" },
    { lvl=10,  name="Robes du Padawan",              model="models/swtor/jedi/padawan_m.mdl" },
    { lvl=20,  name="Robes du Consulaire",           model="models/swtor/jedi/consular_m.mdl" },
    { lvl=35,  name="Robes de l'Érudit Jedi",        model="models/swtor/jedi/sage_m.mdl" },
    { lvl=51,  name="Armure du Chevalier Jedi",      model="models/swtor/jedi/knight_m.mdl" },
    { lvl=65,  name="Tenue de la Sentinelle",        model="models/swtor/jedi/sentinel_m.mdl" },
    { lvl=81,  name="Armure du Gardien Jedi",        model="models/swtor/jedi/guardian_m.mdl" },
    { lvl=111, name="Tenue de l'Ombre Jedi",         model="models/swtor/jedi/shadow_m.mdl" },
    { lvl=200, name="✦ Robes du Maître Jedi",        model="models/swtor/jedi/master_m.mdl" },
    { lvl=230, name="Grand Maître Robes",            model="models/swtor/jedi/grandmaster_m.mdl" },
    { lvl=250, name="✦ Tenue du Conseiller Légende", model="models/swtor/jedi/legend_consular_m.mdl" },
    { lvl=270, name="Voix de la Force Robes",        model="models/swtor/jedi/legend_voice_m.mdl" },
    { lvl=300, name="✦ Tenue de la Légende Jedi",    model="models/swtor/jedi/legend_jedi_m.mdl" },
}

print("[SW:TOR Niveaux] Système 300 niveaux chargé ✓ (80min/niveau, 400h max)")
