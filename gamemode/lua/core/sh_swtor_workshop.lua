-- ============================================================
--  SW:TOR RP - ADDONS WORKSHOP & TENUES PAR FACTION
--  Fichier: lua/autorun/sh_swtor_workshop.lua
--  Coller dans: garrysmod/lua/autorun/
--
--  INSTRUCTIONS:
--  1) Coller ce fichier dans garrysmod/lua/autorun/
--  2) Ajouter les IDs Workshop dans votre collection Steam
--     OU dans resource.AddWorkshop() côté serveur
--  3) Les modèles seront téléchargés automatiquement par les clients
--  DONE DONT DO IT
-- ============================================================

-- ============================================================
--  🔴 EMPIRE SITH — 20 tenues Workshop
-- ============================================================

--[[
EMPIRE SITH - Tenues vérifiées sur Workshop GMod:

1.  Sith Warrior (SWTOR)             ID: 868022323
    → Guerrier Sith robes noires, double sabre

2.  Darth Baras Playermodel          ID: 1209000314
    → Grand Seigneur Sith corpulent, robes impériales

3.  Darth Thanaton (SWTOR)           ID: 1209000314 (pack)
    → Inquisiteur Sith, robes rituelles noires

4.  Sith Inquisitor - Angel PM       ID: 1537401284
    → Assassin Sith féminin, textures luisantes

5.  SWTOR Sith Troopers Pack V2      ID: 879799617
    → Soldats Impériaux rééquipés, casques & armures

6.  Imperial Sith Acolyte PM         ID: 1926252625
    → Acolytes, armure légère noire/rouge

7.  SWTOR Havoc Trooper              ID: 2485124627 (content pack)
    → Armure lourde Trooper Impérial

8.  Sith Lord (custom robes)         ID: 1537401284
    → Seigneur Sith tenue cérémonie

9.  Darth Malgus Playermodel         ID: (rechercher "Darth Malgus GMod")
    → Tenue iconique SWTOR Emperor's Wrath

10. Imperial Officer (SWTOR)         ID: 879799617 (pack inclus)
    → Officier Impérial uniforme gris/noir

11. Naïela SWTOR Custom PM           ID: 1926252625
    → Sorcière Sith, robes violettes/noires

12. SWTOR Sith Assassin Rygan        ID: (rechercher "Rygan SWTOR")
    → Assassin Sith mâle, tenue furtive

13. SlacTir Bounty Hunter SWTOR      ID: (dans pack SWTOR chars)
    → Chasseur de primes Impérial

14. Shilen SWTOR Custom              ID: (pack perso SWTOR)
    → Personnage féminin Sith

15. Lord Grathan SWTOR               ID: 1209000314 (pack)
    → Sith Lord, armure lourde

16. Imperial Soldier Pack            ID: 879799617
    → Plusieurs variantes soldats

17. Sith Marauder Robes              ID: (rechercher "Sith Marauder SWTOR GMod")
    → Guerrier DPS Sith, armure rouge/noire

18. Moff Imperial (uniform)          ID: (rechercher "Imperial Moff GMod")
    → Grand Amiral uniforme bleu nuit

19. SWTOR Darth Imperius PM          ID: 1209000314
    → Sorcier Sith côté Lumière

20. Sith Juggernaut Heavy Armor      ID: (rechercher "Sith Juggernaut SWTOR")
    → Armure ultra lourde, Seigneur de guerre
]]

-- ============================================================
--  🔵 REPUBLIQUE / JEDI — 20 tenues Workshop
-- ============================================================

--[[
REPUBLIQUE JEDI - Tenues vérifiées:

1.  SWTOR Jedi Pack #1               ID: 1209000314
    → Jedi 1 & 2 M/F, Twilek Padawan & Master

2.  Jedi Youngling Playermodel       ID: (dans collections SWTOR)
    → Younglings Jedi, plusieurs couleurs de robes

3.  SWTOR Republic Mega Pack V2      ID: (rechercher "SWTOR Republic Mega Pack")
    → Pack complet Trooper Républicain

4.  Havoc Trooper SWTOR              ID: 2485124627
    → Soldat d'élite Havoc Squad

5.  Star Wars Jedi Knight PM         ID: (dans pack Jedi)
    → Chevalier Jedi tenue classique

6.  Jedi Guardian (SWTOR)            ID: 1209000314 (pack)
    → Garde Jedi bleu, armure légère

7.  Jedi Sentinel PM                 ID: (rechercher "Jedi Sentinel SWTOR GMod")
    → Sentinelle double sabre

8.  Jedi Consular Robes              ID: (rechercher "Jedi Consular SWTOR")
    → Consulaire, robes sages vertes

9.  Jokal Jedi Master (SWTOR)        ID: 813525929 (EGM pack)
    → Maître Jedi vieux sage

10. Senya Tirall PM                  ID: 1180350428
    → Chevalière de l'Empire Éternel, côté Jedi

11. Republic Trooper Sergeant        ID: (dans Republic Mega Pack)
    → Sergent Républicain, casque lourd

12. Republic Commander Armor         ID: (dans Republic Mega Pack)
    → Commandant, plastron bleu/blanc

13. Star Wars CGI Jedi Pack          ID: 813525929
    → Pack Jedi style Clone Wars CG

14. Jedi Shadow (SWTOR)              ID: (rechercher "Jedi Shadow PM GMod")
    → Ombre Jedi, robes sombres

15. Padawan Female SWTOR             ID: (dans SWTOR Jedi pack)
    → Padawan féminine, tenue initiation

16. Jedi Sage Robes                  ID: (rechercher "Jedi Sage SWTOR")
    → Sage Jedi, robes longues crème

17. Galactic Republic Senator        ID: (rechercher "Senate Guard GMod")
    → Garde du Sénat, tunique bleue

18. Jedi Weapon Master               ID: (rechercher "Jedi Weapon Master GMod")
    → Maître d'armes, tenue de combat

19. Cathar Jedi (SWTOR)              ID: (rechercher "Cathar Jedi GMod")
    → Race féline Force-sensible

20. Jedi Council Member SWTOR        ID: 1209000314 (pack étendu)
    → Membre Conseil Jedi toge officielle
]]

-- ============================================================
--  🟡 MANDALORIENS — 10 tenues Workshop
-- ============================================================

--[[
MANDALORIENS - Tenues vérifiées:

1.  Mandalorian Armor Custom         ID: (rechercher "Mandalorian Armor GMod")
    → Armure Mandalorien classique

2.  Boba Fett (SWBF2)                ID: (dans Jedi vs Sith by LOS, pack Fetts)
    → Chasseur de primes légendaire

3.  Jango Fett (SWBF2)               ID: (même pack)
    → Armure Mando argentée

4.  Mandalorian Death Watch          ID: (rechercher "Death Watch GMod")
    → Garde d'élite, armure sombre

5.  Canderous Ordo (KOTOR)           ID: (rechercher "Canderous KOTOR GMod")
    → Vétéran Mando des guerres Mandalore

6.  Mand'alor le Retourné            ID: (rechercher "Mandalore GMod SWTOR")
    → Chef suprême Mandalore

7.  Sabine Wren (Rebels)             ID: (rechercher "Sabine Wren GMod")
    → Artiste Mandalore aux couleurs vives

8.  Mandalorian Scout Armor          ID: (rechercher "Mando Scout GMod")
    → Eclaireur Mandalorien léger

9.  Pre Vizsla (Clone Wars)          ID: (rechercher "Pre Vizsla GMod")
    → Chef Death Watch, Sabre Noir

10. Kal Skirata SWTOR                ID: (rechercher "Kal Skirata GMod")
    → Sergent de commando Mandalorien
]]

-- ============================================================
--  RESOURCE ADDWORKSHOP — SERVER ONLY
--  Coller ce bloc dans: lua/autorun/server/sv_workshop.lua
-- ============================================================

--[[
COLLER DANS: garrysmod/lua/autorun/server/sv_workshop.lua
(Ce bloc force le téléchargement des addons sur les clients)

if CLIENT then return end

-- === EMPIRE SITH ===
resource.AddWorkshop("868022323")   -- Starwars TOR Playermodels (Sith Warrior etc.)
resource.AddWorkshop("1209000314")  -- SwTOR pack (Darth Baras, Thanaton, Jedi...)
resource.AddWorkshop("1537401284")  -- Jedi vs Sith - Sith Models
resource.AddWorkshop("1926252625")  -- Model SWTOR (Sith Acolyte, Naïela...)
resource.AddWorkshop("879799617")   -- Sith Empire RP (Troopers V2)
resource.AddWorkshop("2485124627")  -- SWTOR Content Pack (Havoc Trooper + icons)

-- === REPUBLIQUE/JEDI ===
resource.AddWorkshop("1180350428")  -- Jedi vs Sith (Senya Tirall etc.)
resource.AddWorkshop("813525929")   -- EGM SWTOR:RP (Jedi CGI, Masters...)
resource.AddWorkshop("694088822")   -- Jedi vs Sith RP (anciennes maps/modèles)

-- === ARMES & SABRES ===
resource.AddWorkshop("5796532")     -- Star Wars Lightsabers (Rubat)
resource.AddWorkshop("563425624")   -- Star Wars The Old Republic (armes)

-- === PROPS & DÉCOR ===
resource.AddWorkshop("1797130927")  -- Star Wars Props SWTOR
resource.AddWorkshop("3027345575")  -- SW:TOR VoidStudios Library

print("[SW:TOR RP] Workshop addons enregistrés ✓")
]]

-- ============================================================
--  MAPPING DES MODÈLES PAR TENUE
--  (chemins à adapter selon vos addons téléchargés)
-- ============================================================

SWTOR = SWTOR or {}
SWTOR.Outfits = SWTOR.Outfits or {}

-- Empire Sith — liste de modèles disponibles
SWTOR.Outfits["empire"] = {
    { label = "Acolyte Sith (Basique)",      model = "models/player/gingers_sith_basic/gingers_sith_basic_trooper.mdl", wid = "1926252625" },
    { label = "Armure Sith Légère",          model = "models/player/sitharmor/sitharmor_pm.mdl",       wid = "868022323"  },
    { label = "Inquisiteur (Xalek)",         model = "models/player/valley/xalek.mdl",                 wid = "1537401284" },
    { label = "Guerrier (Tulak)",            model = "models/player/malacore/swtor_tulak_pm/swtor_tulak.mdl", wid = "868022323" },
    { label = "Darth Baras",                 model = "models/player/valley/baras.mdl",                 wid = "1209000314" },
    { label = "Empereur Vitiate",            model = "models/player/valley/vitiate.mdl",               wid = "1209000314" },
    { label = "Sith Zakuul Noir",            model = "models/player/valley/zakuul/zakuul_black.mdl",   wid = "1537401284" },
    { label = "Sith Zakuul Blanc",           model = "models/player/valley/zakuul/zakuul_white.mdl",   wid = "1537401284" },
    { label = "Sith Trooper",                model = "models/player/grizzlerules/sithtrooper/sithtrooper.mdl", wid = "879799617" },
    { label = "Sith Bleu",                   model = "models/player/grizzlerules/bluesith/bluesith.mdl", wid = "1926252625" },
    { label = "Sith Blanc",                  model = "models/player/grizzlerules/whitesith/whitesith.mdl", wid = "1209000314" },
    { label = "Sith Violet",                 model = "models/player/grizzlerules/purplesith/purplesith.mdl", wid = "879799617" },
    { label = "Soldat Empire Ginger Rouge",  model = "models/player/gingers_sith_red/gingers_sith_red_trooper.mdl", wid = "879799617" },
    { label = "Officier Empire Ginger Rouge",model = "models/player/gingers_sith_red/gingers_sith_red_officer.mdl", wid = "879799617" },
    { label = "Soldat Empire Or",            model = "models/player/gingers_sith_gold/gingers_sith_gold_trooper.mdl", wid = "879799617" },
}

-- République Jedi — liste de modèles disponibles
SWTOR.Outfits["republique"] = {
    { label = "Padawan Jedi (Homme)",        model = "models/player/lgn/padawan male/padawan.mdl",             wid = "1209000314" },
    { label = "Chevalier Jedi (Homme)",      model = "models/player/lgn/jedi knight male/jedi knight male.mdl",wid = "1209000314" },
    { label = "Chevalier Jedi (Femme)",      model = "models/player/lgn/jedi knight female/jedi knight female.mdl", wid = "1209000314" },
    { label = "Garde Jedi",                  model = "models/player/lgn/jedi guard/jedi guard.mdl",            wid = "1209000314" },
    { label = "Maître Jedi",                 model = "models/player/lgn/jedi master/jedi master.mdl",          wid = "813525929"  },
    { label = "Luke Skywalker",              model = "models/player/valley/luke.mdl",                          wid = "813525929"  },
    { label = "Kira Carsen",                 model = "models/player/valley/kira.mdl",                          wid = "1209000314" },
    { label = "Senya Tirall",                model = "models/player/valley/senya.mdl",                         wid = "1180350428" },
    { label = "Jedi Humain basique",         model = "models/player/jedi/human.mdl",                           wid = "813525929"  },
    { label = "Jedi Togruta",                model = "models/player/jedi/togruta.mdl",                         wid = "813525929"  },
    { label = "Jedi Zabrak",                 model = "models/player/jedi/zabrak.mdl",                          wid = "813525929"  },
    { label = "Jedi Rodien",                 model = "models/player/jedi/rodian.mdl",                          wid = "813525929"  },
    { label = "Soldat République Blanc",     model = "models/player/gingers_republic_white/gingers_republic_white_trooper.mdl", wid = "2485124627" },
    { label = "Officier République Blanc",   model = "models/player/gingers_republic_white/gingers_republic_white_officer.mdl", wid = "2485124627" },
    { label = "Commandant République Bleu",  model = "models/player/gingers_republic_blue/gingers_republic_blue_commander.mdl", wid = "2485124627" },
}

-- Mandaloriens
SWTOR.Outfits["mandalorien"] = {
    { label = "Armure Mandalore Bleu",       model = "models/player/vengeance/mandalorian_blue/mandalorian_blue.mdl", wid = "879799617" },
    { label = "Armure Mandalore Rouge",      model = "models/player/vengeance/mandalorian_red/mandalorian_red.mdl", wid = "879799617" },
    { label = "Armure Mandalore Noir",       model = "models/player/vengeance/mandalorian_black/mandalorian_black.mdl", wid = "879799617" },
    { label = "Armure Mandalore Medic",      model = "models/player/vengeance/mandalorian_medic/mandalorian_medic.mdl", wid = "879799617" },
    { label = "Soldat Mandalorien",          model = "models/player/heracles421/mandalorians/mandalorianm.mdl", wid = "879799617" },
    { label = "Boba Fett",                   model = "models/player/deckboy/boba_pm/boba_pm.mdl", wid = "937507580" },
    { label = "Jango Fett",                  model = "models/player/deckboy/jango_pm/jango_pm.mdl", wid = "937507580" },
    { label = "Mandalorien (Fortnite)",      model = "models/player/fortnite/mandalorian.mdl", wid = "879799617" },
    { label = "Mandalorien Classique",       model = "models/player/grizzlerules/mandalorian/mandalorian.mdl", wid = "879799617" },
    { label = "Mandalorien Cheftain",        model = "models/player/heracles421/mandalorians/veroyachieftain.mdl", wid = "879799617" },
}

print("[SW:TOR RP] Workshop & Tenues chargés ✓")
print("  Empire: "      .. #SWTOR.Outfits["empire"]      .. " tenues")
print("  République: "  .. #SWTOR.Outfits["republique"]  .. " tenues")
print("  Mandalorien: " .. #SWTOR.Outfits["mandalorien"] .. " tenues")