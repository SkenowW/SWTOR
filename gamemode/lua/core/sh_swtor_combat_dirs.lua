-- ============================================================
--  SW:TOR RP — COMBAT DIRECTIONNEL (Shared Base)
--  lua/autorun/sh_swtor_combat_dirs.lua
--  Détecte Z/Q/S/D + état du joueur → détermine l'attaque
-- ============================================================

SWTOR = SWTOR or {}
SWTOR.Combat = SWTOR.Combat or {}

-- ============================================================
--  DIRECTIONS DE MOUVEMENT (ZQSD français)
-- ============================================================
-- Retourne la direction d'entrée active du joueur
-- Appelé côté CLIENT uniquement
function SWTOR.Combat.GetMoveDir()
    local fwd  = input.IsKeyDown(KEY_Z) or input.IsKeyDown(KEY_W)  -- Z/W avancer
    local back = input.IsKeyDown(KEY_S)                             -- S reculer
    local left = input.IsKeyDown(KEY_Q) or input.IsKeyDown(KEY_A)  -- Q/A gauche
    local rght = input.IsKeyDown(KEY_D)                             -- D droite
    local jump = input.IsKeyDown(KEY_SPACE)
    local duck = input.IsKeyDown(KEY_LCONTROL)

    if jump  then return "jump"      end
    if duck  then return "duck"      end
    if fwd  and left  then return "fwd_left"  end
    if fwd  and rght  then return "fwd_right" end
    if back and left  then return "back_left" end
    if back and rght  then return "back_right"end
    if fwd  then return "forward"  end
    if back then return "backward" end
    if left then return "left"     end
    if rght then return "right"    end
    return "neutral"
end

-- ============================================================
--  DÉFINITION DES COUPS PAR STYLE + DIRECTION
--
--  Chaque coup a :
--    name     — Nom affiché
--    anim     — ACT_ utilisé
--    dmg_mult — Multiplicateur de dégâts
--    range    — Portée (units)
--    arc      — Angle du cône de hit (degrés)
--    knockback— Recul sur la cible
--    stagger  — Interrompt l'attaque de la cible
--    special  — Effet spécial (string)
--    sound_idx— Index son (1-4)
--    cd       — Cooldown propre (0 = dépend du SWEP)
-- ============================================================

SWTOR.Combat.Moves = {}

-- ════════════════════════════════════════════════════════════
--  STYLE 1 : SABRE SIMPLE (swtor_lightsaber)
--  Style équilibré, portée et dégâts moyens
-- ════════════════════════════════════════════════════════════
SWTOR.Combat.Moves["single"] = {

    neutral = {
        name     = "Frappe Standard",
        anim     = ACT_MELEE_ATTACK_SWING,
        dmg_mult = 1.0,
        range    = 80,
        arc      = 60,
        knockback= 0,
        stagger  = false,
        sound_idx= 1,
    },

    forward = {
        name     = "Frappe Plongeante",
        anim     = ACT_MELEE_ATTACK1,
        dmg_mult = 1.3,
        range    = 110,    -- Plus longue portée
        arc      = 30,     -- Cône étroit = précis
        knockback= 150,
        stagger  = true,
        special  = "lunge", -- Projection vers l'avant
        sound_idx= 2,
    },

    backward = {
        name     = "Riposte Arrière",
        anim     = ACT_MELEE_ATTACK2,
        dmg_mult = 0.8,
        range    = 75,
        arc      = 180,    -- Frappe derrière
        knockback= 200,
        stagger  = false,
        special  = "spin_back",
        sound_idx= 3,
    },

    left = {
        name     = "Balayage Gauche",
        anim     = ACT_MELEE_ATTACK_SWING,
        dmg_mult = 0.9,
        range    = 90,
        arc      = 120,    -- Large arc
        knockback= 100,
        stagger  = false,
        sound_idx= 1,
    },

    right = {
        name     = "Balayage Droit",
        anim     = ACT_MELEE_ATTACK_SWING,
        dmg_mult = 0.9,
        range    = 90,
        arc      = 120,
        knockback= 100,
        stagger  = false,
        sound_idx= 1,
    },

    fwd_left = {
        name     = "Tranchant Diagonal",
        anim     = ACT_MELEE_ATTACK1,
        dmg_mult = 1.15,
        range    = 95,
        arc      = 80,
        knockback= 120,
        stagger  = true,
        sound_idx= 2,
    },

    fwd_right = {
        name     = "Estoc Puissant",
        anim     = ACT_MELEE_ATTACK1,
        dmg_mult = 1.2,
        range    = 100,
        arc      = 45,
        knockback= 180,
        stagger  = true,
        special  = "pierce",
        sound_idx= 2,
    },

    back_left = {
        name     = "Pirouette Gauche",
        anim     = ACT_MELEE_ATTACK2,
        dmg_mult = 0.85,
        range    = 85,
        arc      = 200,
        knockback= 80,
        stagger  = false,
        special  = "spin_360",
        sound_idx= 3,
    },

    back_right = {
        name     = "Pirouette Droite",
        anim     = ACT_MELEE_ATTACK2,
        dmg_mult = 0.85,
        range    = 85,
        arc      = 200,
        knockback= 80,
        stagger  = false,
        special  = "spin_360",
        sound_idx= 3,
    },

    jump = {
        name     = "Frappe Sautée",
        anim     = ACT_MELEE_ATTACK1,
        dmg_mult = 1.5,    -- Grosse récompense
        range    = 95,
        arc      = 60,
        knockback= 300,
        stagger  = true,
        special  = "slam",
        sound_idx= 4,
    },

    duck = {
        name     = "Crochet Bas",
        anim     = ACT_MELEE_ATTACK2,
        dmg_mult = 0.75,
        range    = 70,
        arc      = 90,
        knockback= 0,
        stagger  = true,   -- Interrompt la garde
        special  = "low_sweep",
        sound_idx= 1,
    },
}

-- ════════════════════════════════════════════════════════════
--  STYLE 2 : DOUBLE SABRE / DUAL WIELD (swtor_lightsaber_dual)
--  Deux sabres — très rapide, faibles dégâts unités, grande zone
-- ════════════════════════════════════════════════════════════
SWTOR.Combat.Moves["dual"] = {

    neutral = {
        name     = "Tourbillon Jumelé",
        anim     = ACT_MELEE_ATTACK_SWING,
        dmg_mult = 0.8,    -- Moins par coup mais deux lames
        range    = 85,
        arc      = 90,
        knockback= 60,
        stagger  = false,
        special  = "dual_hit",  -- Frappe deux fois
        sound_idx= 1,
    },

    forward = {
        name     = "Double Estoc",
        anim     = ACT_MELEE_ATTACK1,
        dmg_mult = 1.1,
        range    = 95,
        arc      = 40,
        knockback= 100,
        stagger  = true,
        special  = "dual_hit",
        sound_idx= 2,
    },

    backward = {
        name     = "Croix Inversée",
        anim     = ACT_MELEE_ATTACK2,
        dmg_mult = 0.9,
        range    = 80,
        arc      = 160,
        knockback= 120,
        stagger  = false,
        special  = "dual_spin_back",
        sound_idx= 3,
    },

    left = {
        name     = "Cisaille Gauche",
        anim     = ACT_MELEE_ATTACK_SWING,
        dmg_mult = 0.85,
        range    = 88,
        arc      = 140,
        knockback= 80,
        stagger  = false,
        special  = "dual_hit",
        sound_idx= 1,
    },

    right = {
        name     = "Cisaille Droite",
        anim     = ACT_MELEE_ATTACK_SWING,
        dmg_mult = 0.85,
        range    = 88,
        arc      = 140,
        knockback= 80,
        stagger  = false,
        special  = "dual_hit",
        sound_idx= 1,
    },

    fwd_left = {
        name     = "Lames Croisées",
        anim     = ACT_MELEE_ATTACK1,
        dmg_mult = 1.0,
        range    = 90,
        arc      = 100,
        knockback= 90,
        stagger  = true,
        special  = "dual_cross",
        sound_idx= 2,
    },

    fwd_right = {
        name     = "Tempête Jumelée",
        anim     = ACT_MELEE_ATTACK1,
        dmg_mult = 1.05,
        range    = 90,
        arc      = 100,
        knockback= 90,
        stagger  = true,
        special  = "dual_cross",
        sound_idx= 2,
    },

    back_left = {
        name     = "Moulin à Vent",
        anim     = ACT_MELEE_ATTACK2,
        dmg_mult = 0.7,
        range    = 100,
        arc      = 360,    -- Tour complet
        knockback= 150,
        stagger  = false,
        special  = "spin_360",
        sound_idx= 4,
    },

    back_right = {
        name     = "Tourbillon Total",
        anim     = ACT_MELEE_ATTACK2,
        dmg_mult = 0.7,
        range    = 100,
        arc      = 360,
        knockback= 150,
        stagger  = false,
        special  = "spin_360",
        sound_idx= 4,
    },

    jump = {
        name     = "Pluie de Lames",
        anim     = ACT_MELEE_ATTACK1,
        dmg_mult = 1.4,
        range    = 95,
        arc      = 120,
        knockback= 250,
        stagger  = true,
        special  = "dual_slam",
        sound_idx= 4,
    },

    duck = {
        name     = "Faucheuse Basse",
        anim     = ACT_MELEE_ATTACK2,
        dmg_mult = 0.8,
        range    = 95,
        arc      = 180,
        knockback= 0,
        stagger  = true,
        special  = "low_dual",
        sound_idx= 1,
    },
}

-- ════════════════════════════════════════════════════════════
--  STYLE 3 : SABRE DOUBLE LAME (swtor_lightsaber_double)
--  Bâton double — très large, lent, dévastateur
-- ════════════════════════════════════════════════════════════
SWTOR.Combat.Moves["double"] = {

    neutral = {
        name     = "Arc Bifide",
        anim     = ACT_MELEE_ATTACK_SWING,
        dmg_mult = 1.1,
        range    = 100,    -- Portée supérieure
        arc      = 100,
        knockback= 100,
        stagger  = false,
        sound_idx= 1,
    },

    forward = {
        name     = "Brise-Garde",
        anim     = ACT_MELEE_ATTACK1,
        dmg_mult = 1.6,    -- Très puissant
        range    = 110,
        arc      = 35,
        knockback= 250,
        stagger  = true,
        special  = "guard_break",  -- Brise la garde à coup sûr
        sound_idx= 2,
    },

    backward = {
        name     = "Pivot de Bâton",
        anim     = ACT_MELEE_ATTACK2,
        dmg_mult = 1.0,
        range    = 105,
        arc      = 220,
        knockback= 180,
        stagger  = false,
        special  = "double_spin",
        sound_idx= 3,
    },

    left = {
        name     = "Fauchage Gauche",
        anim     = ACT_MELEE_ATTACK_SWING,
        dmg_mult = 1.0,
        range    = 105,
        arc      = 150,
        knockback= 120,
        stagger  = false,
        sound_idx= 1,
    },

    right = {
        name     = "Fauchage Droit",
        anim     = ACT_MELEE_ATTACK_SWING,
        dmg_mult = 1.0,
        range    = 105,
        arc      = 150,
        knockback= 120,
        stagger  = false,
        sound_idx= 1,
    },

    fwd_left = {
        name     = "Fauche Diagonale",
        anim     = ACT_MELEE_ATTACK1,
        dmg_mult = 1.25,
        range    = 108,
        arc      = 90,
        knockback= 160,
        stagger  = true,
        sound_idx= 2,
    },

    fwd_right = {
        name     = "Coup Croisé Bas",
        anim     = ACT_MELEE_ATTACK1,
        dmg_mult = 1.25,
        range    = 108,
        arc      = 90,
        knockback= 160,
        stagger  = true,
        sound_idx= 2,
    },

    back_left = {
        name     = "Rotation Complète",
        anim     = ACT_MELEE_ATTACK2,
        dmg_mult = 1.1,
        range    = 115,
        arc      = 360,
        knockback= 200,
        stagger  = true,
        special  = "spin_360",
        sound_idx= 4,
    },

    back_right = {
        name     = "Moulinet de Bâton",
        anim     = ACT_MELEE_ATTACK2,
        dmg_mult = 1.1,
        range    = 115,
        arc      = 360,
        knockback= 200,
        stagger  = true,
        special  = "spin_360",
        sound_idx= 4,
    },

    jump = {
        name     = "Écrasement du Bâton",
        anim     = ACT_MELEE_ATTACK1,
        dmg_mult = 2.0,    -- Le plus puissant du jeu
        range    = 110,
        arc      = 80,
        knockback= 500,
        stagger  = true,
        special  = "mega_slam",
        sound_idx= 4,
    },

    duck = {
        name     = "Balayage Rasant",
        anim     = ACT_MELEE_ATTACK2,
        dmg_mult = 0.9,
        range    = 110,
        arc      = 200,
        knockback= 0,
        stagger  = true,
        special  = "low_sweep",
        sound_idx= 1,
    },
}

-- ════════════════════════════════════════════════════════════
--  STYLE 4 : VIBROLAME (swtor_vibroblade) — Mandalorien
--  Lourd, lent, brutal. Ignore partiellement la garde.
-- ════════════════════════════════════════════════════════════
SWTOR.Combat.Moves["vibro"] = {

    neutral = {
        name     = "Taille Brute",
        anim     = ACT_MELEE_ATTACK_SWING,
        dmg_mult = 1.2,
        range    = 85,
        arc      = 70,
        knockback= 80,
        stagger  = false,
        special  = "armor_pierce",  -- Ignore 20% armure
        sound_idx= 1,
    },

    forward = {
        name     = "Charge Beskar",
        anim     = ACT_MELEE_ATTACK1,
        dmg_mult = 1.7,
        range    = 100,
        arc      = 30,
        knockback= 300,
        stagger  = true,
        special  = "armor_pierce",
        sound_idx= 2,
    },

    backward = {
        name     = "Contre-Attaque",
        anim     = ACT_MELEE_ATTACK2,
        dmg_mult = 1.4,
        range    = 85,
        arc      = 180,
        knockback= 200,
        stagger  = true,
        special  = "armor_pierce",
        sound_idx= 3,
    },

    left = {
        name     = "Crochet Gauche",
        anim     = ACT_MELEE_ATTACK_SWING,
        dmg_mult = 1.1,
        range    = 80,
        arc      = 100,
        knockback= 120,
        stagger  = false,
        special  = "armor_pierce",
        sound_idx= 1,
    },

    right = {
        name     = "Crochet Droit",
        anim     = ACT_MELEE_ATTACK_SWING,
        dmg_mult = 1.1,
        range    = 80,
        arc      = 100,
        knockback= 120,
        stagger  = false,
        special  = "armor_pierce",
        sound_idx= 1,
    },

    fwd_left = {
        name     = "Entaille Profonde",
        anim     = ACT_MELEE_ATTACK1,
        dmg_mult = 1.4,
        range    = 90,
        arc      = 60,
        knockback= 150,
        stagger  = true,
        special  = "bleed",  -- Saignement: -5 HP/s pendant 3s
        sound_idx= 2,
    },

    fwd_right = {
        name     = "Pourfendu",
        anim     = ACT_MELEE_ATTACK1,
        dmg_mult = 1.5,
        range    = 90,
        arc      = 50,
        knockback= 180,
        stagger  = true,
        special  = "bleed",
        sound_idx= 2,
    },

    back_left = {
        name     = "Pivot Meurtrier",
        anim     = ACT_MELEE_ATTACK2,
        dmg_mult = 1.3,
        range    = 88,
        arc      = 270,
        knockback= 160,
        stagger  = false,
        special  = "armor_pierce",
        sound_idx= 3,
    },

    back_right = {
        name     = "Retournement Brutal",
        anim     = ACT_MELEE_ATTACK2,
        dmg_mult = 1.3,
        range    = 88,
        arc      = 270,
        knockback= 160,
        stagger  = false,
        special  = "armor_pierce",
        sound_idx= 3,
    },

    jump = {
        name     = "Exécution Aérienne",
        anim     = ACT_MELEE_ATTACK1,
        dmg_mult = 2.2,    -- Le plus haut dégâts du jeu
        range    = 90,
        arc      = 60,
        knockback= 600,
        stagger  = true,
        special  = "execution",  -- Si cible < 25% HP : mort instantanée
        sound_idx= 4,
    },

    duck = {
        name     = "Coup de Genou",
        anim     = ACT_MELEE_ATTACK2,
        dmg_mult = 0.8,
        range    = 65,
        arc      = 80,
        knockback= 0,
        stagger  = true,
        special  = "stun_short",  -- Stun 1s
        sound_idx= 1,
    },
}

-- ════════════════════════════════════════════════════════════
--  MAPPING CLASSE → STYLE DE COMBAT
-- ════════════════════════════════════════════════════════════
SWTOR.Combat.ClassStyle = {
    guerrier_sith       = "single",
    inquisiteur_sith    = "double",   -- Sabre double lame
    agent_imperial      = nil,         -- Pas de mêlée
    soldat_imperial     = nil,
    chevalier_jedi      = "single",
    consul_jedi         = "single",
    contrebandier       = nil,
    trooper_republicain = nil,
    chasseur_primes     = nil,
    guerrier_mando      = "vibro",
}

-- Overrides si le joueur a changé son arme en jeu
SWTOR.Combat.WeaponStyle = {
    swtor_lightsaber        = "single",
    swtor_lightsaber_dual   = "dual",
    swtor_lightsaber_double = "double",
    swtor_vibroblade        = "vibro",
}

-- Récupérer le style actif d'un joueur
function SWTOR.Combat.GetStyle(ply)
    -- Priorité : arme équipée
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) then
        local style = SWTOR.Combat.WeaponStyle[wep:GetClass()]
        if style then return style end
    end
    -- Fallback : classe
    return SWTOR.Combat.ClassStyle[ply.swtor_class or ""] or "single"
end

-- Récupérer le coup selon direction + style
function SWTOR.Combat.GetMove(ply, dir)
    local style  = SWTOR.Combat.GetStyle(ply)
    local moves  = SWTOR.Combat.Moves[style]
    if not moves then return nil end
    return moves[dir] or moves["neutral"]
end

print("[SW:TOR] Combat directionnel chargé ✓ (4 styles × 11 directions = 44 coups uniques)")
