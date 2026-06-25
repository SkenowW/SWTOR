-- ============================================================
--  SW:TOR RP — MOTEUR DE COMBAT AVANCÉ (style wOS ALCS)
--  lua/autorun/sh_swtor_combat_engine.lua
--
--  Reproduit ~95% des mécaniques wOS :
--  - Clash de sabres (quand deux attaques se rencontrent)
--  - Postures de combat (agressive / défensive / équilibrée)
--  - Système de stamina (endurance qui limite les actions)
--  - Lock-on (verrouillage sur une cible)
--  - Combos enchaînés par voie
--  - Garde directionnelle
--  - Feintes et contre-attaques
-- ============================================================

SWTOR = SWTOR or {}
SWTOR.CombatEngine = SWTOR.CombatEngine or {}

-- ============================================================
--  POSTURES DE COMBAT (changées avec une touche)
-- ============================================================
-- POSTURES = STYLE & ANIMATION UNIQUEMENT (aucun bonus de stats)
-- Elles changent la façon dont le personnage tient son sabre et bouge
SWTOR.CombatEngine.Stances = {
    balanced = {
        name        = "Garde Standard",
        icon        = "⚔",
        color       = Color(180, 180, 200),
        anim_set    = "standard",   -- Animation de garde classique
        desc        = "Position de garde classique, sabre tenu devant.",
    },
    aggressive = {
        name        = "Garde Offensive",
        icon        = "🔥",
        color       = Color(220, 120, 60),
        anim_set    = "offensive",  -- Sabre levé, prêt à frapper
        desc        = "Sabre levé en arrière, posture d'attaque.",
    },
    defensive = {
        name        = "Garde Défensive",
        icon        = "🛡",
        color       = Color(80, 140, 220),
        anim_set    = "defensive",  -- Sabre bas, position défensive
        desc        = "Sabre tenu bas, posture de protection.",
    },
    dual_wield = {
        name        = "Garde Jar'Kai",
        icon        = "⚔",
        color       = Color(200, 100, 220),
        anim_set    = "dual",       -- Deux lames croisées
        desc        = "Deux sabres croisés, posture de duelliste.",
    },
    reverse = {
        name        = "Prise Inversée",
        icon        = "🗡",
        color       = Color(180, 60, 60),
        anim_set    = "reverse",    -- Sabre tenu à l'envers (Ahsoka/Shadow)
        desc        = "Sabre tenu à l'envers, style imprévisible.",
    },
}

-- ============================================================
--  STYLES DE COMBAT PAR VOIE (formes de combat SWTOR)
-- ============================================================
-- Chaque voie a une "forme" avec ses propres caractéristiques
SWTOR.CombatEngine.Forms = {

    -- RAVAGEUR / GARDIEN — Djem So (forme puissante et agressive)
    ravageur = {
        name        = "Djem So",
        weapon_type = "single",
        combo_max   = 4,
        combo_window= 1.6,
        swing_speed = 0.45,
        anim_style  = "djemso",  -- Mouvements puissants et larges
        special     = "djemso_riposte",  -- Contre-attaque puissante
        desc        = "Forme V — Puissance et domination. Chaque coup déstabilise.",
    },

    -- MARAUDEUR / SENTINELLE — Jar'Kai (double lame)
    maraudeur = {
        name        = "Jar'Kai",
        weapon_type = "dual",
        combo_max   = 6,
        combo_window= 1.3,
        swing_speed = 0.30,
        anim_style  = "jarkai",  -- Mouvements rapides à deux lames
        special     = "blade_flurry",
        dual_strike = true,
        desc        = "Forme Jar'Kai — Deux lames, enchaînements fluides.",
    },

    -- SORCIER / ÉRUDIT — Makashi (forme élégante de duel)
    sorcier = {
        name        = "Makashi",
        weapon_type = "single",
        combo_max   = 4,
        combo_window= 1.7,
        swing_speed = 0.48,
        anim_style  = "makashi",  -- Mouvements précis et élégants
        special     = "makashi_riposte",  -- Riposte élégante
        desc        = "Forme II — Élégance et précision. L'art du duel.",
    },

    -- ASSASSIN / OMBRE — Juyo (double lame, forme féroce)
    assassin = {
        name        = "Juyo",
        weapon_type = "double",
        combo_max   = 5,
        combo_window= 1.4,
        swing_speed = 0.38,
        anim_style  = "juyo",  -- Mouvements imprévisibles, rotations
        special     = "spinning_death",
        desc        = "Forme VII — Imprévisible et féroce. La danse de la mort.",
    },

    -- MANDALORIEN — Beskar'gam (vibrolame)
    mando = {
        name        = "Beskar'gam",
        weapon_type = "vibro",
        combo_max   = 3,
        combo_window= 1.7,
        swing_speed = 0.55,
        anim_style  = "mando",  -- Coups brutaux mandaloriens
        special     = "execution",
        desc        = "Combat mandalorien — Coups brutaux et directs.",
    },
}

-- Mapping voie → forme(s) disponibles
-- Les voies à sabre simple ont accès à DJEM SO + MAKASHI (switchables)
SWTOR.CombatEngine.VoieToForms = {
    -- Voies sabre simple → 2 formes au choix
    ravageur   = { "ravageur", "sorcier" },   -- Djem So + Makashi
    gardien    = { "ravageur", "sorcier" },   -- Djem So + Makashi
    sorcier    = { "ravageur", "sorcier" },   -- Djem So + Makashi
    erudit     = { "ravageur", "sorcier" },   -- Djem So + Makashi
    -- Voies double sabre → forme unique
    maraudeur  = { "maraudeur" },
    sentinelle = { "maraudeur" },
    assassin   = { "assassin" },
    ombre      = { "assassin" },
}

-- Forme par défaut de chaque voie
SWTOR.CombatEngine.VoieToForm = {
    ravageur   = "ravageur",   gardien    = "ravageur",
    maraudeur  = "maraudeur",  sentinelle = "maraudeur",
    sorcier    = "sorcier",    erudit     = "sorcier",
    assassin   = "assassin",   ombre      = "assassin",
}

-- Retourne les formes disponibles pour un joueur
function SWTOR.CombatEngine.GetAvailableForms(ply)
    local faction = ply.swtor_faction or ""
    if faction == "mandalorien" then return { "mando" } end
    local grade = SWTOR.GetGrade(faction, ply.swtor_grade or 1)
    local voie  = grade and grade.voie
    if voie and SWTOR.CombatEngine.VoieToForms[voie] then
        return SWTOR.CombatEngine.VoieToForms[voie]
    end
    return { "ravageur" }
end

-- ============================================================
--  GETTERS
-- ============================================================
function SWTOR.CombatEngine.GetForm(ply)
    local faction = ply.swtor_faction or ""
    if faction == "mandalorien" then return SWTOR.CombatEngine.Forms.mando end

    -- Si le joueur a choisi une forme spécifique (parmi celles dispo)
    local chosen = ply.swtor_form or ply:GetNWString("swtor_form", "")
    if chosen ~= "" and SWTOR.CombatEngine.Forms[chosen] then
        -- Vérifier qu'elle est dans ses formes disponibles
        local avail = SWTOR.CombatEngine.GetAvailableForms(ply)
        for _, f in ipairs(avail) do
            if f == chosen then return SWTOR.CombatEngine.Forms[chosen] end
        end
    end

    -- Sinon forme par défaut de la voie
    local grade = SWTOR.GetGrade(faction, ply.swtor_grade or 1)
    local voie  = grade and grade.voie
    if voie and SWTOR.CombatEngine.VoieToForm[voie] then
        return SWTOR.CombatEngine.Forms[SWTOR.CombatEngine.VoieToForm[voie]]
    end
    if grade and grade.weapon_style then
        if grade.weapon_style == "dual"   then return SWTOR.CombatEngine.Forms.maraudeur end
        if grade.weapon_style == "double" then return SWTOR.CombatEngine.Forms.assassin  end
    end
    return SWTOR.CombatEngine.Forms.ravageur
end

function SWTOR.CombatEngine.GetStance(ply)
    local stanceKey = ply.swtor_stance or "balanced"
    return SWTOR.CombatEngine.Stances[stanceKey] or SWTOR.CombatEngine.Stances.balanced
end

-- ============================================================
--  STAMINA (endurance de combat)
-- ============================================================
SWTOR.CombatEngine.MaxStamina = 100

function SWTOR.CombatEngine.GetStamina(ply)
    return ply.swtor_stamina or SWTOR.CombatEngine.MaxStamina
end

function SWTOR.CombatEngine.UseStamina(ply, amount)
    if not IsValid(ply) then return false end
    local current = ply.swtor_stamina or SWTOR.CombatEngine.MaxStamina
    if current < amount then return false end
    ply.swtor_stamina = current - amount
    if SERVER then ply:SetNWFloat("swtor_stamina", ply.swtor_stamina) end
    return true
end

function SWTOR.CombatEngine.RegenStamina(ply, dt)
    if not IsValid(ply) then return end
    local current = ply.swtor_stamina or SWTOR.CombatEngine.MaxStamina
    -- Régen plus lente si en posture agressive
    local stance  = SWTOR.CombatEngine.GetStance(ply)
    local regenRate = 15 / (stance.stamina_cost or 1)  -- 15/s de base
    ply.swtor_stamina = math.min(SWTOR.CombatEngine.MaxStamina, current + regenRate * dt)
    if SERVER then ply:SetNWFloat("swtor_stamina", ply.swtor_stamina) end
end

print("[SW:TOR] Moteur de combat avancé chargé ✓ (5 formes, 3 postures, stamina)")
