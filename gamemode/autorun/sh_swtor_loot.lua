-- ============================================================
--  SW:TOR RP — SYSTÈME DE LOOT COSMÉTIQUE
--  lua/autorun/sh_swtor_loot.lua
--  Aucun bonus stat — 100% visuel/prestige
-- ============================================================

SWTOR = SWTOR or {}
SWTOR.Loot = SWTOR.Loot or {}

-- ============================================================
--  RARETÉS
-- ============================================================
SWTOR.Loot.Rarities = {
    { key="commun",       label="Commun",       color=Color(180,180,180), weight=50  },
    { key="peu_commun",   label="Peu Commun",   color=Color(80, 220, 80), weight=30  },
    { key="rare",         label="Rare",         color=Color(50, 120, 255),weight=12  },
    { key="epique",       label="Épique",       color=Color(160,50, 220), weight=5   },
    { key="legendaire",   label="Légendaire",   color=Color(255,180,0),   weight=2   },
    { key="mythique",     label="Mythique",     color=Color(220,50, 50),  weight=0.8 },
    { key="transcendant", label="Transcendant", color=Color(255,255,255), weight=0.2 },
}

-- ============================================================
--  CATALOGUE COSMÉTIQUES
-- ============================================================
SWTOR.Loot.Items = {

    -- ════════ SABRES ════════

    ["lame_bleue"] = {
        name    = "Cristal Bleu",
        type    = "sabre_color",
        rarity  = "commun",
        factions= { "republique" },
        desc    = "La couleur classique de l'Ordre Jedi.",
        effect  = { r=30, g=120, b=255 },
    },
    ["lame_rouge"] = {
        name    = "Cristal Rouge",
        type    = "sabre_color",
        rarity  = "commun",
        factions= { "empire" },
        desc    = "Le rouge cramoisi des Sith.",
        effect  = { r=255, g=20, b=20 },
    },
    ["lame_verte"] = {
        name    = "Cristal Vert",
        type    = "sabre_color",
        rarity  = "peu_commun",
        factions= { "republique" },
        desc    = "Couleur des Consuls Jedi.",
        effect  = { r=30, g=220, b=60 },
    },
    ["lame_violette"] = {
        name    = "Cristal Violet",
        type    = "sabre_color",
        rarity  = "rare",
        factions= { "empire", "republique" },
        desc    = "Rare — maîtrise des deux côtés de la Force.",
        effect  = { r=180, g=40, b=220 },
    },
    ["lame_orange"] = {
        name    = "Cristal Orange",
        type    = "sabre_color",
        rarity  = "rare",
        factions= { "empire", "republique", "mandalorien" },
        desc    = "Couleur rare des guerriers non-alignés.",
        effect  = { r=255, g=140, b=20 },
    },
    -- ════════ SABRES COULEUR EXCLUSIFS FONDATEURS (non lootables) ════════

    ["lame_blanche"] = {
        name      = "Cristal Blanc Pur",
        type      = "sabre_color",
        lootable  = false,
        exclusive = true,
        hrp_req   = "fondateur",   -- Fondateur uniquement
        factions  = { "republique" },
        desc      = "Purifié de toute influence obscure. Réservé aux Fondateurs.",
        effect    = { r=255, g=255, b=255 },
    },
    ["lame_noire"] = {
        name      = "Sabre Noir (Darksaber)",
        type      = "sabre_color",
        lootable  = false,
        exclusive = true,
        hrp_req   = "fondateur",
        factions  = { "mandalorien" },
        desc      = "L'arme sacrée des Mand'alor. Réservée aux Fondateurs.",
        effect    = { r=20, g=20, b=20, core_white=false, dark=true },
    },
    ["lame_eclipse"] = {
        name      = "Éclipse Sith",
        type      = "sabre_color",
        lootable  = false,
        exclusive = true,
        hrp_req   = "fondateur",
        factions  = { "empire" },
        desc      = "Lame noire bordée de rouge. Réservée aux Fondateurs.",
        effect    = { r=30, g=0, b=0, border_r=255, border_g=20, border_b=20, smoke=true },
    },
    ["lame_originelle"] = {
        name      = "Lumière Originelle Jedi",
        type      = "sabre_color",
        lootable  = false,
        exclusive = true,
        hrp_req   = "fondateur",
        factions  = { "republique" },
        desc      = "Lumière blanche pure avec halo doré. Réservée aux Fondateurs.",
        effect    = { r=255, g=255, b=255, halo_r=255, halo_g=200, halo_b=50 },
    },

    -- ════════ EFFETS DE LAME — LOOTABLES ════════

    ["lame_instable"] = {
        name      = "Cristal Instable",
        type      = "sabre_effect",
        lootable  = true,
        rarity    = "transcendant",  -- Super rare 4% (via drop_weight)
        drop_weight = 4,             -- 4% de chance dans la rareté transcendant
        factions  = { "empire", "republique", "mandalorien" },
        desc      = "Énergie qui crépite — lame agitée.",
        effect    = { flicker=true, flicker_rate=0.05 },
    },
    ["lame_trainee"] = {
        name      = "Traînée Lumineuse",
        type      = "sabre_effect",
        lootable  = true,
        rarity    = "transcendant",  -- Super rare 4%
        drop_weight = 4,
        factions  = { "empire", "republique", "mandalorien" },
        desc      = "Laisse une traînée lumineuse lors des swings.",
        effect    = { trail=true, trail_len=0.15 },
    },
    ["lame_mythique"] = {
        name      = "Force Primordiale",
        type      = "sabre_effect",
        lootable  = false,
        exclusive = true,
        hrp_req   = "fondateur",     -- Fondateur et Responsable
        hrp_req_min_level = 4,       -- Niveau 4 = Responsable+
        factions  = { "empire", "republique" },
        desc      = "Lame vivante — distorsion. Fondateurs et Responsables uniquement.",
        effect    = { distortion=true, flicker=true, particles="mythic_sparks" },
    },
    ["lame_transcendant"] = {
        name      = "Fracture de Réalité",
        type      = "sabre_effect",
        lootable  = false,
        exclusive = true,
        hrp_req   = "fondateur",
        hrp_req_min_level = 4,
        factions  = { "empire", "republique" },
        desc      = "La lame semble exister hors du temps. Fondateurs et Responsables.",
        effect    = { glitch=true, reality_break=true, particles="void_rift" },
    },

    -- ════════ AURAS JOUEUR ════════
    -- ⚠ AUCUNE AURA N'EST LOOTABLE
    -- Toutes assignées uniquement par admin via swtor_setaura <joueur> <aura_key>
    -- Les 4 auras exclusives correspondent à des grades/rôles uniques sur le serveur

    ["aura_furie"] = {
        name      = "Furie",
        type      = "aura",
        lootable  = false,   -- JAMAIS dans les drops
        exclusive = true,    -- Admin uniquement
        factions  = { "empire" },
        desc      = "Réservée au grade Furie. Aura orange sombre pulsante, fumée brûlante.",
        -- Orange sombre — brûlant, intense, dangereux
        effect    = {
            body_color    = Color(180, 80,  0),    -- Orange sombre sur le corps
            particle_color= Color(200, 100, 10),   -- Particules orangées
            smoke         = true,
            smoke_color   = Color(120, 40,  0),    -- Fumée sombre
            pulse         = true,
            pulse_speed   = 1.8,
            glow_radius   = 80,
            particles     = "burning_embers",
        },
    },

    ["aura_mains"] = {
        name      = "Mains de l'Empereur",
        type      = "aura",
        lootable  = false,
        exclusive = true,
        factions  = { "empire" },
        desc      = "Réservée aux Mains de l'Empereur. Aura rouge sombre avec voix distordue.",
        -- Rouge sombre — pouvoir corrompu, serviteur direct
        effect    = {
            body_color    = Color(140, 10,  10),   -- Rouge sombre
            particle_color= Color(180, 20,  20),
            smoke         = true,
            smoke_color   = Color(80,  0,   0),    -- Fumée noire-rouge
            pulse         = true,
            pulse_speed   = 1.2,
            glow_radius   = 70,
            distort_voice = true,                  -- Voix légèrement distordue (pitch down)
            particles     = "dark_crimson",
        },
    },

    ["aura_empereur"] = {
        name      = "Aura de l'Empereur",
        type      = "aura",
        lootable  = false,
        exclusive = true,
        factions  = { "empire" },
        desc      = "Réservée à l'Empereur Sith. Aura noire absolue — la Force elle-même se courbe.",
        -- Noir absolu — au-delà du pouvoir, présence oppressante
        effect    = {
            body_color    = Color(5,   0,   5),    -- Quasi noir
            particle_color= Color(30,  0,   30),   -- Particules noires violacées
            smoke         = true,
            smoke_color   = Color(0,   0,   0),    -- Fumée noire pure
            pulse         = true,
            pulse_speed   = 0.6,                   -- Lent, imposant
            glow_radius   = 120,
            distortion    = true,                  -- Distorsion de l'air autour
            env_distort   = true,                  -- Légère distorsion de l'environnement proche
            full_aura     = true,
            darkness_field= true,                  -- Zone légèrement assombrie autour
            particles     = "void_emperor",
            sound_loop    = "ambient/machines/thumper_hit.wav",
        },
    },

    ["aura_legende_jedi"] = {
        name      = "Légende Jedi",
        type      = "aura",
        lootable  = false,
        exclusive = true,
        factions  = { "republique" },
        desc      = "Réservée au Grand Maître légendaire. Aura blanche pure — la Force incarnée.",
        -- Blanc pur — lumière absolue, sérénité totale
        effect    = {
            body_color    = Color(255, 255, 255),  -- Blanc pur
            particle_color= Color(240, 240, 255),  -- Blanc légèrement bleuté
            smoke         = false,
            pulse         = true,
            pulse_speed   = 0.8,
            glow_radius   = 130,
            full_aura     = true,
            holy_light    = true,                  -- Halo lumineux au sol
            particles     = "pure_light",
            sound_loop    = "ambient/levels/citadel/portal_beam_shoot1.wav",
        },
    },

    -- ════════ TRACES DE MOUVEMENT ════════

    -- ════════ TRACES DE MOUVEMENT (toutes lootables — 1% drop) ════════

    ["trace_base"] = {
        name        = "Trace Lumineuse",
        type        = "movement_trail",
        lootable    = true,
        rarity      = "transcendant",  -- Extrêmement rare
        drop_weight = 1,               -- 1% de chance
        factions    = { "empire", "republique", "mandalorien" },
        desc        = "Légère traînée de lumière lors du sprint.",
        effect      = { color=Color(200,200,200), fade=0.3 },
    },
    ["trace_sith"] = {
        name        = "Sillage Sombre",
        type        = "movement_trail",
        lootable    = true,
        rarity      = "transcendant",
        drop_weight = 1,
        factions    = { "empire" },
        desc        = "Fumée rouge-noire derrière le Sith.",
        effect      = { color=Color(180,20,20), smoke=true, fade=0.5 },
    },
    ["trace_jedi"] = {
        name        = "Sillage de Lumière",
        type        = "movement_trail",
        lootable    = true,
        rarity      = "transcendant",
        drop_weight = 1,
        factions    = { "republique" },
        desc        = "Particules de Force bleues au passage.",
        effect      = { color=Color(80,150,255), particles=true, fade=0.4 },
    },
    ["trace_glitch"] = {
        name        = "Glitch Dimensionnel",
        type        = "movement_trail",
        lootable    = false,
        exclusive   = true,
        hrp_req     = "fondateur",     -- Fondateurs uniquement
        hrp_req_min_level = 5,
        factions    = { "empire", "republique", "mandalorien" },
        desc        = "La réalité se fracture sur ton passage. Fondateurs uniquement.",
        effect      = { glitch=true, color=Color(200,100,255), reality_break=true },
    },

    -- ════════ EMPREINTES ════════

    -- ════════ EMPREINTES (non lootables — Fondateurs uniquement) ════════

    ["empreintes_feu"] = {
        name      = "Pas de Feu",
        type      = "footprint",
        lootable  = false,
        exclusive = true,
        hrp_req   = "fondateur",
        hrp_req_min_level = 5,
        factions  = { "empire", "mandalorien" },
        desc      = "Brûlures lumineuses au sol. Fondateurs uniquement.",
        effect    = { color=Color(255,100,0), decal="burn" },
    },
    ["empreintes_force"] = {
        name      = "Pas de Force",
        type      = "footprint",
        lootable  = false,
        exclusive = true,
        hrp_req   = "fondateur",
        hrp_req_min_level = 5,
        factions  = { "republique" },
        desc      = "Symboles Jedi lumineux au sol. Fondateurs uniquement.",
        effect    = { color=Color(80,180,255), decal="force_symbol" },
    },
    ["empreintes_void"] = {
        name      = "Pas du Néant",
        type      = "footprint",
        lootable  = false,
        exclusive = true,
        hrp_req   = "fondateur",
        hrp_req_min_level = 5,
        factions  = { "empire", "republique", "mandalorien" },
        desc      = "Le sol se fracture sous tes pieds. Fondateurs uniquement.",
        effect    = { color=Color(255,255,255), decal="void_crack", glitch=true },
    },
}

-- ============================================================
--  HELPER : Roll une rareté aléatoire
-- ============================================================
function SWTOR.Loot.RollRarity()
    local total = 0
    for _, r in ipairs(SWTOR.Loot.Rarities) do total = total + r.weight end
    local roll  = math.random() * total
    local cumul = 0
    for _, r in ipairs(SWTOR.Loot.Rarities) do
        cumul = cumul + r.weight
        if roll <= cumul then return r.key end
    end
    return "commun"
end

-- Roll un item aléatoire pour une faction
function SWTOR.Loot.RollItem(factionKey, rarityKey)
    local pool = {}
    for key, item in pairs(SWTOR.Loot.Items) do
        if item.rarity == rarityKey then
            for _, f in ipairs(item.factions or {}) do
                if f == factionKey then
                    table.insert(pool, key)
                    break
                end
            end
        end
    end
    if #pool == 0 then return nil end
    return pool[math.random(#pool)]
end

-- Obtenir la couleur d'une rareté
function SWTOR.Loot.GetRarityColor(rarityKey)
    for _, r in ipairs(SWTOR.Loot.Rarities) do
        if r.key == rarityKey then return r.color end
    end
    return Color(180,180,180)
end

function SWTOR.Loot.GetRarityLabel(rarityKey)
    for _, r in ipairs(SWTOR.Loot.Rarities) do
        if r.key == rarityKey then return r.label end
    end
    return "Commun"
end

local count = table.Count(SWTOR.Loot.Items)
print("[SW:TOR] Loot cosmétique chargé ✓ (" .. count .. " items, 7 raretés)")
