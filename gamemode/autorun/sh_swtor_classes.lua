-- ============================================================
--  SW:TOR RP — CLASSES PAR FACTION (gameplay différencié)
--  lua/autorun/sh_swtor_classes.lua
--  Chaque faction a des classes distinctes avec stats uniques
-- ============================================================

SWTOR = SWTOR or {}
SWTOR.Classes = {}

-- ============================================================
--  EMPIRE SITH — 4 CLASSES
-- ============================================================

SWTOR.Classes["guerrier_sith"] = {
    name        = "Guerrier Sith",
    faction     = "empire",
    description = "Combattant au corps-à-corps, maître du sabre. Force brute et domination physique.",
    icon        = "⚔",
    color       = Color(220, 40, 40),
    -- Stats de base
    stats = {
        hp          = 200,   -- Tank offensif
        armor       = 60,
        speed       = 190,   -- Légèrement lent (armure lourde)
        force_regen = 8,     -- Régén Force lente
        force_max   = 80,
    },
    -- Arme de départ
    default_weapon  = "swtor_lightsaber",
    weapon_color    = "red",   -- Couleur du sabre
    -- Compétences débloquées par grade
    abilities = {
        [1] = { id = "force_push_dark",  name = "Répulsion Sith",   icon = "💨" },
        [2] = { id = "saber_throw",      name = "Lancer de Sabre",  icon = "🌀" },
        [3] = { id = "force_charge",     name = "Assaut Force",     icon = "⚡" },
        [4] = { id = "intimidating_roar",name = "Rugissement",      icon = "😤" },
        [5] = { id = "force_choke",      name = "Étranglement",     icon = "🤚", hrp_req_min_level = 4 },
        [6] = { id = "blade_storm",      name = "Tempête de Lames", icon = "🌪" },
        [8] = { id = "unstoppable",      name = "Implacable",       icon = "🛡"  },
        [10]= { id = "force_crush",      name = "Écrasement Force", icon = "💥" },
        [12]= { id = "furious_strike",   name = "Frappe Furieuse",  icon = "☠"  },
    },
    passive = {
        melee_dmg_bonus   = 1.3,   -- +30% dégâts mêlée
        hp_regen          = 2,     -- +2 HP/s en combat
        knockback_resist  = true,  -- Résiste aux répulsions
    },
    playstyle = "Mêlée agressive. Tanke et détruit en ligne droite.",
}

SWTOR.Classes["inquisiteur_sith"] = {
    name        = "Inquisiteur Sith",
    faction     = "empire",
    description = "Manipulateur de la Force. Attaques à distance, foudre et magie noire. Trompeur et mortel.",
    icon        = "⚡",
    color       = Color(180, 40, 220),
    stats = {
        hp          = 140,   -- Fragile
        armor       = 20,
        speed       = 220,   -- Très rapide
        force_regen = 20,    -- Force régén rapide
        force_max   = 150,
    },
    default_weapon  = "swtor_lightsaber",
    weapon_color    = "red",
    abilities = {
        [1] = { id = "force_lightning",   name = "Foudre de Force",   icon = "⚡" },
        [2] = { id = "force_shock",       name = "Choc de Force",     icon = "🔵" },
        [3] = { id = "force_drain",       name = "Drain de Force",    icon = "🌑" },
        [4] = { id = "overload",          name = "Surcharge",         icon = "💢" },
        [5] = { id = "force_storm",       name = "Tempête de Force",  icon = "🌩" },
        [6] = { id = "dark_heal",         name = "Soin Obscur",       icon = "💜" },
        [8] = { id = "phase_walk",        name = "Marche Fantôme",    icon = "👻" },
        [10]= { id = "force_lightning2",  name = "Chaîne de Foudre",  icon = "⚡⚡"},
        [12]= { id = "death_field",       name = "Champ de Mort",     icon = "💀", hrp_req_min_level = 4 },
    },
    passive = {
        force_dmg_bonus   = 1.5,   -- +50% dégâts Force
        lightning_chain   = true,  -- Foudre peut rebondir
        stealth_minor     = true,  -- Légère réduction de détection
    },
    playstyle = "DPS distance. Gère la Force comme ressource principale.",
}

SWTOR.Classes["agent_imperial"] = {
    name        = "Agent Impérial",
    faction     = "empire",
    description = "Sniper et espion de l'Empire. Furtivité, poison, tirs de précision. Élimine avant d'être vu.",
    icon        = "🎯",
    color       = Color(80, 80, 160),
    stats = {
        hp          = 160,
        armor       = 30,
        speed       = 210,
        force_regen = 5,    -- Peu de Force (classe non-Force)
        force_max   = 30,
    },
    default_weapon  = "swtor_sniper",
    weapon_color    = nil,
    abilities = {
        [1] = { id = "snipe",            name = "Tir de Précision",  icon = "🎯" },
        [2] = { id = "stealth",          name = "Camouflage",        icon = "👻" },
        [3] = { id = "corrosive_dart",   name = "Dard Corrosif",     icon = "☠" },
        [4] = { id = "explosive_probe",  name = "Sonde Explosive",   icon = "💣" },
        [5] = { id = "cover",            name = "Couverture",        icon = "🛡" },
        [6] = { id = "laze_target",      name = "Marquage Laser",    icon = "🔴" },
        [8] = { id = "series_of_shots",  name = "Rafale Ciblée",     icon = "🔫" },
        [10]= { id = "ambush",           name = "Embuscade",         icon = "🌑" },
        [12]= { id = "cover_pulse",      name = "Impulsion de Couverture", icon = "💫" },
    },
    passive = {
        ranged_dmg_bonus  = 1.4,
        stealth_speed     = true,  -- Vite en furtivité
        poison_stacks      = true,  -- Les poisons s'accumulent
    },
    playstyle = "Sniper furtif. S'approche, marque, élimine, disparaît.",
}

SWTOR.Classes["soldat_imperial"] = {
    name        = "Soldat Impérial",
    faction     = "empire",
    description = "Infanterie d'élite de l'Empire. Blaster lourd, grenades, armure maximale. Le bouclier humain.",
    icon        = "🛡",
    color       = Color(140, 20, 20),
    stats = {
        hp          = 240,   -- Max HP
        armor       = 80,    -- Max armure
        speed       = 170,   -- Lent
        force_regen = 0,
        force_max   = 0,
    },
    default_weapon  = "swtor_blaster_heavy",
    weapon_color    = nil,
    abilities = {
        [1] = { id = "full_auto",        name = "Tir Automatique",   icon = "🔫" },
        [2] = { id = "frag_grenade",     name = "Grenade Fragm.",    icon = "💣" },
        [3] = { id = "ion_pulse",        name = "Impulsion Ionique", icon = "⚡" },
        [4] = { id = "riot_strike",      name = "Coup de Bouclier",  icon = "🛡" },
        [5] = { id = "adrenaline_rush",  name = "Rush Adrénaline",   icon = "💪" },
        [6] = { id = "mortar_volley",    name = "Volée de Mortier",  icon = "🎆" },
        [8] = { id = "shoulder_cannon",  name = "Canon Épaule",      icon = "🚀" },
        [10]= { id = "fortification",    name = "Fortification",     icon = "🏰" },
        [12]= { id = "supercharged_cell",name = "Cellule Surchargée",icon = "⚡💥"},
    },
    passive = {
        armor_bonus       = 1.5,
        blaster_dmg_bonus = 1.2,
        grenade_range     = 1.3,
    },
    playstyle = "Tank défensif. Tient la ligne et protège les alliés.",
}

-- ============================================================
--  REPUBLIQUE / JEDI — 4 CLASSES
-- ============================================================

SWTOR.Classes["chevalier_jedi"] = {
    name        = "Chevalier Jedi",
    faction     = "republique",
    description = "Gardien de la paix, maître du sabre. Équilibre entre force offensive et protection des alliés.",
    icon        = "✦",
    color       = Color(50, 130, 255),
    stats = {
        hp          = 190,
        armor       = 50,
        speed       = 200,
        force_regen = 12,
        force_max   = 100,
    },
    default_weapon  = "swtor_lightsaber",
    weapon_color    = "blue",
    abilities = {
        [1] = { id = "force_push_jedi",  name = "Répulsion Jedi",    icon = "💨" },
        [2] = { id = "saber_throw",      name = "Lancer de Sabre",   icon = "🌀" },
        [3] = { id = "force_sweep",      name = "Balayage Force",    icon = "💫" },
        [4] = { id = "guardian_leap",    name = "Bond du Gardien",   icon = "🦘" },
        [5] = { id = "force_stasis",     name = "Stase de Force",    icon = "❄" },
        [6] = { id = "riposte",          name = "Riposte",           icon = "⚔" },
        [8] = { id = "awe",              name = "Révérence",         icon = "✨" },
        [10]= { id = "blade_barrier",    name = "Barrière de Lames", icon = "🌀" },
        [12]= { id = "force_sanctified", name = "Sanctification",    icon = "☀" },
    },
    passive = {
        defense_bonus     = 1.3,
        reflect_chance    = 0.15,  -- 15% de refléter les tirs blaster
        ally_heal_aura    = true,  -- +2 HP/s aux alliés proches
    },
    playstyle = "Mêlée équilibré. Protège et contre-attaque.",
}

SWTOR.Classes["consul_jedi"] = {
    name        = "Consul Jedi",
    faction     = "republique",
    description = "Maître de la sagesse et du soin. Télékinésie, boucliers de Force, soutien de combat.",
    icon        = "🌟",
    color       = Color(80, 200, 180),
    stats = {
        hp          = 150,
        armor       = 20,
        speed       = 215,
        force_regen = 25,
        force_max   = 200,   -- Plus grande réserve Force
    },
    default_weapon  = "swtor_lightsaber",
    weapon_color    = "green",
    abilities = {
        [1] = { id = "force_heal",       name = "Soin de Force",     icon = "💚" },
        [2] = { id = "force_lift",       name = "Lévitation",        icon = "🌊" },
        [3] = { id = "force_wave",       name = "Vague de Force",    icon = "🌊" },
        [4] = { id = "project",          name = "Projection",        icon = "🪨" },
        [5] = { id = "telekinetic_throw",name = "Jet Télékinétique", icon = "💫" },
        [6] = { id = "force_armor",      name = "Armure de Force",   icon = "🔵" },
        [8] = { id = "rejuvenate",       name = "Régénération",      icon = "💚💚"},
        [10]= { id = "rescue",           name = "Sauvetage",         icon = "🤝" },
        [12]= { id = "force_enlighten",  name = "Illumination Force",icon = "☀💚"},
    },
    passive = {
        heal_bonus        = 1.6,
        force_bonus       = 1.3,
        group_heal_aura   = true,
    },
    playstyle = "Support/Heal. Maintient les alliés en vie, contrôle la zone.",
}

SWTOR.Classes["contrebandier"] = {
    name        = "Contrebandier",
    faction     = "republique",
    description = "Tireur d'élite indépendant. Blasters jumelés, coups fourrés, couverture. Imprévisible et mortel.",
    icon        = "🔫",
    color       = Color(200, 160, 40),
    stats = {
        hp          = 170,
        armor       = 25,
        speed       = 225,   -- Le plus rapide
        force_regen = 0,
        force_max   = 0,
    },
    default_weapon  = "swtor_blaster_dual",
    weapon_color    = nil,
    abilities = {
        [1] = { id = "dirty_kick",       name = "Coup Bas",          icon = "🦶" },
        [2] = { id = "flurry_of_bolts",  name = "Rafale de Tirs",    icon = "🔫" },
        [3] = { id = "flash_grenade",    name = "Grenade Flash",     icon = "💡" },
        [4] = { id = "cover",            name = "Couverture",        icon = "🛡" },
        [5] = { id = "thermal_grenade",  name = "Grenade Thermique", icon = "🔥" },
        [6] = { id = "trick_move",       name = "Feinte",            icon = "🎭" },
        [7] = { id = "vital_shot",       name = "Tir Vital",         icon = "🎯" },
        [9] = { id = "hightail_it",      name = "Retraite Rapide",   icon = "💨" },
        [11]= { id = "lucky_draw",       name = "Tir Chanceux",      icon = "🎲" },
    },
    passive = {
        dual_wield_bonus  = 1.3,
        stealth_attack    = true,  -- Bonus depuis couverture
        credit_bonus      = 1.2,   -- +20% crédits gagnés
    },
    playstyle = "DPS rapide, mobile. Esquive et frappe en continu.",
}

SWTOR.Classes["trooper_republicain"] = {
    name        = "Trooper Républicain",
    faction     = "republique",
    description = "Soldat d'élite de la République. Armure de combat, techno-gadgets, grenades. Résistant et polyvalent.",
    icon        = "⚙",
    color       = Color(30, 100, 200),
    stats = {
        hp          = 230,
        armor       = 75,
        speed       = 175,
        force_regen = 0,
        force_max   = 0,
    },
    default_weapon  = "swtor_blaster_heavy",
    weapon_color    = nil,
    abilities = {
        [1] = { id = "full_auto",        name = "Tir Automatique",   icon = "🔫" },
        [2] = { id = "sticky_grenade",   name = "Grenade Collante",  icon = "💣" },
        [3] = { id = "medical_probe",    name = "Sonde Médicale",    icon = "💊" },
        [4] = { id = "hammershot",       name = "Rafale Marteau",    icon = "🔨" },
        [5] = { id = "combat_medic",     name = "Médecin Combat",    icon = "⚕" },
        [6] = { id = "plasma_grenade",   name = "Grenade Plasma",    icon = "🔥" },
        [8] = { id = "recharge_reload",  name = "Rechargement",      icon = "🔋" },
        [10]= { id = "havoc_training",   name = "Formation Havoc",   icon = "💪" },
        [12]= { id = "assault_plastique",name = "Assaut Plastique",  icon = "🚀" },
    },
    passive = {
        armor_bonus       = 1.4,
        tech_dmg_bonus    = 1.2,
        self_heal_tech    = true,
    },
    playstyle = "Tank/Support. Combine gadgets tech et résistance.",
}

-- ============================================================
--  MANDALORIEN — 2 CLASSES
-- ============================================================

SWTOR.Classes["chasseur_primes"] = {
    name        = "Chasseur de Primes",
    faction     = "mandalorien",
    description = "Mercenaire létal. Jetpack, missiles, flammes et blasters. La classe la plus polyvalente de la galaxie.",
    icon        = "🚀",
    color       = Color(180, 140, 20),
    stats = {
        hp          = 180,
        armor       = 55,
        speed       = 220,
        force_regen = 0,
        force_max   = 0,
    },
    default_weapon  = "swtor_blaster_dual",
    weapon_color    = nil,
    abilities = {
        [1] = { id = "jet_boost",        name = "Propulsion Jet",    icon = "🚀" },
        [2] = { id = "rocket_punch",     name = "Poing-Roquette",    icon = "👊" },
        [3] = { id = "flamethrower",     name = "Lance-Flammes",     icon = "🔥" },
        [4] = { id = "death_from_above", name = "Frappe Aérienne",   icon = "☄" },
        [5] = { id = "missile_blast",    name = "Missile",           icon = "🚀" },
        [6] = { id = "kolto_overcharge", name = "Surcharge Kolto",   icon = "💉" },
        [7] = { id = "neural_dart",      name = "Dard Neural",       icon = "🎯" },
        [9] = { id = "thermal_det",      name = "Détonateur Therm.", icon = "💣" },
        [11]= { id = "unload",           name = "Décharge Totale",   icon = "⚡🔫"},
    },
    passive = {
        jetpack_speed     = true,   -- Double saut/vol court
        bounty_credits    = 1.5,    -- +50% crédits sur kills
        armor_piercing    = 0.15,   -- 15% ignorer armure
    },
    playstyle = "DPS hybride mobile. Saute, brûle, tire, recommence.",
}

SWTOR.Classes["guerrier_mando"] = {
    name        = "Guerrier Mandalorien",
    faction     = "mandalorien",
    description = "Combattant traditionnel. Vibrolame, blaster, honneur. La guerre est son art et sa culture.",
    icon        = "🔱",
    color       = Color(160, 120, 20),
    stats = {
        hp          = 210,
        armor       = 65,
        speed       = 195,
        force_regen = 0,
        force_max   = 0,
    },
    default_weapon  = "swtor_vibroblade",
    weapon_color    = nil,
    abilities = {
        [1] = { id = "vicious_slash",    name = "Taillade Vicieuse", icon = "⚔" },
        [2] = { id = "jetpack_charge",   name = "Charge Jetpack",    icon = "🚀" },
        [3] = { id = "war_cry",          name = "Cri de Guerre",     icon = "😤" },
        [4] = { id = "headbutt",         name = "Coup de Casque",    icon = "🪖" },
        [5] = { id = "gore",             name = "Mise à Mort",       icon = "🩸" },
        [6] = { id = "deadly_saber",     name = "Lame Mortelle",     icon = "🗡" },
        [7] = { id = "intimidate",       name = "Intimidation",      icon = "😡" },
        [9] = { id = "beskar_defense",   name = "Défense Beskar",    icon = "🛡" },
        [11]= { id = "mando_execution",  name = "Exécution Mando",   icon = "💀" },
    },
    passive = {
        melee_dmg_bonus   = 1.35,
        honor_code        = true,   -- Bonus si duel 1v1 (pas en groupe)
        war_cry_buff      = true,   -- Cri booste les alliés Mando
    },
    playstyle = "Mêlée lourde. Honneur du duel, frappe décisive.",
}

-- ============================================================
--  HELPERS
-- ============================================================
function SWTOR.GetClassesForFaction(factionKey)
    local result = {}
    for key, cls in pairs(SWTOR.Classes) do
        if cls.faction == factionKey then
            result[key] = cls
        end
    end
    return result
end

function SWTOR.GetPlayerClass(ply)
    return SWTOR.Classes[ply.swtor_class or ""]
end

function SWTOR.HasAbility(ply, abilityId)
    local cls = SWTOR.GetPlayerClass(ply)
    if not cls then return false end
    local grade = ply.swtor_grade or 1
    for reqGrade, ab in pairs(cls.abilities) do
        if ab.id == abilityId and grade >= reqGrade then return true end
    end
    return false
end

function SWTOR.GetUnlockedAbilities(ply)
    local cls = SWTOR.GetPlayerClass(ply)
    if not cls then return {} end
    local grade = ply.swtor_grade or 1
    local result = {}
    for reqGrade, ab in pairs(cls.abilities) do
        if grade >= reqGrade then
            table.insert(result, ab)
        end
    end
    return result
end

local count = 0
for _ in pairs(SWTOR.Classes) do count = count + 1 end
print("[SW:TOR] Classes chargées ✓ (" .. count .. " classes)")

-- ============================================================
--  RESTRICTION HRP POUR CERTAINES ABILITIES
--  Retourne le niveau HRP minimum requis pour une ability
-- ============================================================
function SWTOR.GetAbilityHRPReq(ply, abilityId)
    local faction = ply.swtor_faction or ""
    local class   = ply.swtor_class   or ""
    local cls     = SWTOR.Classes[class]
    if not cls or not cls.abilities then return 0 end

    for reqGrade, ab in pairs(cls.abilities) do
        if ab.id == abilityId then
            return ab.hrp_req_min_level or 0
        end
    end
    return 0
end
