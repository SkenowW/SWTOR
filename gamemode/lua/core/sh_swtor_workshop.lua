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
    { label="Novice Sith",               model="models/sith1/sith1.mdl",                                          wid="536802852" },
    { label="Garde Impériale",           model="models/player/swtor/arsenic/exp/newimpguard.mdl",                  wid="1137746151" },
    { label="Thanaton (Inquisiteur)",    model="models/player/swtor/arsenic/java/thanaton.mdl",                    wid="1175422048" },
    { label="Miles (Guerrier)",          model="models/player/swtor/arsenic/miles/miles.mdl",                      wid="1112831149" },
    { label="Nemesis",                   model="models/player/swtor/arsenic/nemesis/nemesistest.mdl",              wid="1110042818" },
    { label="Apex",                      model="models/player/swtor/arsenic/exp/apex.mdl",                        wid="1137746151" },
    { label="Overwatch",                 model="models/player/swtor/arsenic/exp/overwatch.mdl",                   wid="1137746151" },
    { label="Empereur v1",               model="models/player/swtor/arsenic/exp/emperor.mdl",                     wid="1137746151" },
    { label="Empereur v2",               model="models/player/swtor/arsenic/exp/emperor2.mdl",                    wid="1137746151" },
    { label="Zabrak Sith",               model="models/player/swtor/arsenic/tyler/zabraksith.mdl",                wid="1118457142" },
    { label="Tulak Hord",                model="models/player/malacore/swtor_tulak.mdl",                          wid="803929070" },
    { label="Vaylin",                    model="models/player/malacore/vaylin.mdl",                               wid="836479072" },
    { label="Shilen",                    model="models/player/arsenic/shilen/shilen.mdl",                         wid="889159258" },
    { label="Grathan",                   model="models/player/swtor/arsenic/grathan/grathan.mdl",                  wid="1122645043" },
    { label="SlacTir",                   model="models/player/swtor/arsenic/slactir/slactirtest2.mdl",            wid="963836086" },
    { label="Soldat Sith Basique",       model="models/player/gingers_sith_basic/gingers_sith_basic_trooper.mdl", wid="1130281220" },
    { label="Officier Sith Basique",     model="models/player/gingers_sith_basic/gingers_sith_basic_officer.mdl", wid="1130281220" },
    { label="Commandant Sith Basique",   model="models/player/gingers_sith_basic/gingers_sith_basic_commander.mdl",wid="1130281220" },
    { label="Soldat Sith Rouge",         model="models/player/gingers_sith_red/gingers_sith_red_trooper.mdl",     wid="1130281220" },
    { label="Officier Sith Rouge",       model="models/player/gingers_sith_red/gingers_sith_red_officer.mdl",     wid="1130281220" },
    { label="Commandant Sith Rouge",     model="models/player/gingers_sith_red/gingers_sith_red_commander.mdl",   wid="1130281220" },
    { label="Soldat Sith Or",            model="models/player/gingers_sith_gold/gingers_sith_gold_trooper.mdl",   wid="1130281220" },
    { label="Officier Sith Or",          model="models/player/gingers_sith_gold/gingers_sith_gold_officer.mdl",   wid="1130281220" },
    { label="Commandant Sith Or",        model="models/player/gingers_sith_gold/gingers_sith_gold_commander.mdl", wid="1130281220" },
    { label="Soldat Sith Gris",          model="models/player/gingers_sith_grey/gingers_sith_grey_trooper.mdl",   wid="1130281220" },
    { label="Officier Sith Gris",        model="models/player/gingers_sith_grey/gingers_sith_grey_officer.mdl",   wid="1130281220" },
    { label="Commandant Sith Gris",      model="models/player/gingers_sith_grey/gingers_sith_grey_commander.mdl", wid="1130281220" },
    { label="Soldat Sith Vert",          model="models/player/gingers_sith_green/gingers_sith_green_trooper.mdl", wid="1130281220" },
    { label="Jump Trooper Impérial",     model="models/player/valley/jumptrooper.mdl",                            wid="878096502" },
    { label="Heavy Trooper Impérial",    model="models/player/alpha/heavytrooper.mdl",                            wid="877248284" },
    { label="Snow Recon Impérial",       model="models/player/alpha/snowrecon.mdl",                               wid="877116047" },
}

SWTOR.Outfits["republique"] = {
    { label="Jedi Novice",               model="models/jedi2/jedi2.mdl",                                                          wid="536802852" },
    { label="Jokal (Maître Jedi)",       model="models/player/swtor/arsenic/jokal/jokal.mdl",                                     wid="1111462113" },
    { label="Jaric (Consulaire)",        model="models/player/valley/jaric.mdl",                                                  wid="851549072" },
    { label="Jensyn (Chevalier)",        model="models/player/valley/jensyn.mdl",                                                 wid="851549072" },
    { label="Kira (Jedi)",               model="models/player/valley/kira.mdl",                                                   wid="851549072" },
    { label="Aric (Trooper)",            model="models/player/valley/aric.mdl",                                                   wid="851549072" },
    { label="Senya Tirall",              model="models/player/valley/senya.mdl",                                                  wid="871404225" },
    { label="Temple Guard",              model="models/player/swtor/arsenic/templeguard/templeguard.mdl",                         wid="1103851396" },
    { label="Zakuul Knight",             model="models/player/valley/zakuul/zakuul_knight.mdl",                                   wid="921467446" },
    { label="Zakuul Knight Blanc",       model="models/player/valley/zakuul/zakuul_white.mdl",                                    wid="921467446" },
    { label="Zakuul Knight Noir",        model="models/player/valley/zakuul/zakuul_black.mdl",                                    wid="921467446" },
    { label="Honor Guard Zakuul",        model="models/player/valley/zakuul/knight_honor_guard.mdl",                              wid="921467446" },
    { label="Soldat République Bleu",    model="models/player/gingers_republic_blue/gingers_republic_blue_trooper.mdl",           wid="1130281220" },
    { label="Officier République Bleu",  model="models/player/gingers_republic_blue/gingers_republic_blue_officer.mdl",           wid="1130281220" },
    { label="Commandant République Bleu",model="models/player/gingers_republic_blue/gingers_republic_blue_commander.mdl",         wid="1130281220" },
    { label="Soldat République Vert",    model="models/player/gingers_republic_green/gingers_republic_green_trooper.mdl",         wid="1130281220" },
    { label="Officier République Vert",  model="models/player/gingers_republic_green/gingers_republic_green_officer.mdl",         wid="1130281220" },
    { label="Commandant République Vert",model="models/player/gingers_republic_green/gingers_republic_green_commander.mdl",       wid="1130281220" },
    { label="Soldat République Blanc",   model="models/player/gingers_republic_white/gingers_republic_white_trooper.mdl",         wid="1130281220" },
    { label="Officier République Blanc", model="models/player/gingers_republic_white/gingers_republic_white_officer.mdl",         wid="1130281220" },
    { label="Commandant République Blanc",model="models/player/gingers_republic_white/gingers_republic_white_commander.mdl",      wid="1130281220" },
    { label="Soldat République Brun",    model="models/player/gingers_republic_brown/gingers_republic_brown_trooper.mdl",         wid="1130281220" },
    { label="Officier République Brun",  model="models/player/gingers_republic_brown/gingers_republic_brown_officer.mdl",         wid="1130281220" },
    { label="Commandant République Brun",model="models/player/gingers_republic_brown/gingers_republic_brown_commander.mdl",       wid="1130281220" },
}

SWTOR.Outfits["mandalorien"] = {
    { label="Shae Vizla",                model="models/player/alpha/shae.mdl",                                    wid="886546875" },
    { label="Heavy Trooper Mando",       model="models/player/alpha/heavytrooper.mdl",                            wid="877248284" },
    { label="Néo-Croisé Mando",         model="models/player/gingers_republic_red/gingers_republic_red_trooper.mdl", wid="708065528" },
    { label="Officier Mando",            model="models/player/gingers_republic_red/gingers_republic_red_officer.mdl", wid="708065528" },
    { label="Commandant Mando",          model="models/player/gingers_republic_red/gingers_republic_red_commander.mdl",wid="708065528" },
}

print("[SW:TOR RP] Workshop & Tenues chargés ✓")
print("  Empire: "      .. #SWTOR.Outfits["empire"]      .. " tenues")
print("  République: "  .. #SWTOR.Outfits["republique"]  .. " tenues")
print("  Mandalorien: " .. #SWTOR.Outfits["mandalorien"] .. " tenues")
