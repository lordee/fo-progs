#define NUMBER_OF_CLASSES 9

typedef struct
{
    float season; // sets of changes
    float old_hp_armor; // use tf2.8 armour/hp defaults
    float spawn_full; // spawn with full loadout of ammo/armour/grens etc
    float number_of_teams;
    float number_of_classes;
    float flag_emulation; // force tf flags
    float team_frags; // show team cap frags for all team members
    float full_team_score; // every team member carry the total frags for the team
    float override_mapclasses; // ignore directions from maps that ban or limit classes
    float max_classes[NUMBER_OF_CLASSES+1];
    float scout_dash;
    float flash_time;
    float medic_no_cuss;
    float concussion_length;
    float lasergren_rotationcount; // how many rotations the nailgren does
    float lasergren_rotationtime; // time each rotation takes
    float lasergren_damage;
    float lasergren_thinktime;
    float lasergren_range;
    float lasergren_reqthinks;
    float lasergren_angleperthink;
    float det_delay; // tf was originally .8, we use .5
    float pipebomb_limit_world;
    float pipebomb_limit_team;
    float pipebomb_limit_player;

} gamesettings_t;
gamesettings_t GameSettings;

class gamemanager_c : entity
{
    float intermission_running;
    float intermission_exittime;
    string nextmap;

    float _flash_dimension;
    get float flash_dimension =
    {
        return _flash_dimension;
    };
    set float flash_dimension =
    {
        if (value == 8)
            _flash_dimension = DIMENSION::FLASH;
        else
            _flash_dimension = value;
    };

    float pipebomb_count_world;

    void () gamemanager_c =
    {
        this.nextthink = time + 0.01;
        this.think = this.FirstFrame;

        this.Precache_Sounds();
        this.Precache_Models();
    };

    // TODO - macro
    nonvirtual void () Precache_Sounds =
    {
        precache_sound(SOUNDS::DASH);
        precache_sound(SOUNDS::SCAN);
        precache_sound(SOUNDS::FLASH);
        precache_sound(SOUNDS::SHOTGUN_SHOOT);
        precache_sound(SOUNDS::SUPERSHOTGUN_SHOOT);
        precache_sound(SOUNDS::ROCKETLAUNCHER_SHOOT);
        precache_sound(SOUNDS::AXE_SHOOT);
        precache_sound(SOUNDS::AXE_HIT);
        precache_sound(SOUNDS::BOUNCE);
        precache_sound(SOUNDS::SHOCK_HIT);
    };

    // TODO - macro
    nonvirtual void () Precache_Models =
    {
        precache_model(MODELS::BUBBLE);
        precache_model(MODELS::GRENADE_FLASH);
        precache_model(MODELS::GRENADE_HAND);
        precache_model(MODELS::GRENADE_SHOCK);
        precache_model(MODELS::VIEW_SHOTGUN);
        precache_model(MODELS::VIEW_SUPERSHOTGUN);
        precache_model(MODELS::VIEW_AXE);
        precache_model(MODELS::VIEW_ROCKETLAUNCHER);
        precache_model(MODELS::ROCKET);
        precache_model(MODELS::GRENADE);
    };

    nonvirtual void () FirstFrame =
    {
        CSQCManager = spawn(csqcmanager_c);
        MenuManager = spawn(menumanager_c);
        this.PopulateGameSettings();
        this.PopulateTeams();
        this.PopulateClasses();

        this.PopulatePostClassesSettings(); // we need classes generated, we could rewrite it...
    };

    nonvirtual void () PopulateGameSettings = 
    {
        GameSettings.number_of_classes = NUMBER_OF_CLASSES; // not sure if i will ever change this...
        GameSettings.season = this.GetSetting(world, "tfs", "tf_season", ftos(SEASON_ONE));
        GameSettings.old_hp_armor = this.GetSetting(world, "oh", "old_hp_armor", "on");
        GameSettings.spawn_full = this.GetSetting(world, "sf", "spawnfull", "on");
        GameSettings.team_frags = this.GetSetting(world, "t", "teamfrags", "off");
        GameSettings.full_team_score = this.GetSetting(world, "fts", "fullteamscore", "off");
        GameSettings.override_mapclasses = this.GetSetting(world, "omc", "override_mapclasses", "off");
        GameSettings.scout_dash = this.GetSetting(world, "sd", "scoutdash", "on");
        GameSettings.flash_time = this.GetSetting(world, "ff", "fo_flashtime", "2");
        GameSettings.medic_no_cuss = this.GetSetting(world, "mnc", "medicnocuss", "on");
        GameSettings.concussion_length = this.GetSetting(world, "cgt", "cussgrentime", "on"); // bad naming
        GameSettings.lasergren_rotationcount = this.GetSetting(world, "lgrc", "lasergren_rotationcount", "2"); // bad naming
        GameSettings.lasergren_rotationtime = this.GetSetting(world, "lgrt", "lasergren_rotationtime", "1");
        GameSettings.lasergren_damage = this.GetSetting(world, "lgd", "lasergren_damage", "20");
        GameSettings.lasergren_thinktime = this.GetSetting(world, "lgtt", "lasergren_thinktime", "0.01");
        GameSettings.lasergren_range = this.GetSetting(world, "lgr", "lasergren_range", "150");
        GameSettings.lasergren_reqthinks = (GameSettings.lasergren_rotationcount * GameSettings.lasergren_rotationtime) / GameSettings.lasergren_thinktime;
        GameSettings.lasergren_angleperthink = (GameSettings.lasergren_rotationcount * 360) / GameSettings.lasergren_reqthinks;
        GameSettings.det_delay = this.GetSetting(world, "dd", "det_delay", "0.5");
        GameSettings.pipebomb_limit_world = this.GetSetting(world, "dw", "pipebomb_limit_world", "-1");
        GameSettings.pipebomb_limit_team = this.GetSetting(world, "dt", "pipebomb_limit_team", "-1");
        GameSettings.pipebomb_limit_player = this.GetSetting(world, "dp", "pipebomb_limit_player", "6");
    };

    nonvirtual void () PopulatePostClassesSettings = 
    {
        for(float i = 0; i <= GameSettings.number_of_classes; i++)
        {
            string setting = strcat("cr_", Classes[i].classname);
            float val = GameManager.GetSetting(world, setting, setting, 0);
            GameSettings.max_classes[i] = val;
        }
    };

    //if ent is world, return serverinfo, if ent is a player, return that client's setinfo key
    nonvirtual float (entity ent, string ps_short, string ps_setting, string ps_default) GetSetting = 
    {
        string st;

        st = infokey(ent, ps_short);
        if (st == string_null) 
        {
            st = infokey(ent, ps_setting);
            if (st == string_null) {
                st = ps_default;
            }
        }

        switch (st)
        {
            case "on":
                return TRUE;
            case "off":
                return FALSE;
            default:
                return stof(st);
        }
    };

    nonvirtual void () PopulateClasses =
    {
        Classes = memalloc(sizeof(*Classes)*(GameSettings.number_of_classes+1));
        this.ProcessClass(CLASS::SCOUT);
        this.ProcessClass(CLASS::SOLDIER);
        this.ProcessClass(CLASS::DEMOMAN);
    };

    nonvirtual void (CLASS class) ProcessClass =
    {
        // imagine if default values on structs was a thing!
        string tclassname = "bloop";
        float tmax_speed = 0, tmax_strafe_speed = 0, tmax_armor_type = 0, tinit_armor_type = 0;
        float tinit_armor_classes = 0, tillegal_bit = 0, tweapon1 = 0, tweapon2 = 0, tweapon3 = 0, tweapon4 = 0;
        float ttf_attributes = 0, tmax_shells = 0, tinit_shells = 0, tmax_nails = 0, tinit_nails = 0;
        float tmax_rockets = 0, tinit_rockets = 0, tmax_cells = 0, tinit_cells = 0, ttype_gren1 = 0;
        float ttype_gren2 = 0, tmax_health = 0, tmax_armor = 0, tinit_armor = 0, tmax_gren1 = 0;
        float tmax_gren2 = 0, tinit_gren1 = 0, tinit_gren2 = 0, tmax_activegren2 = 0;

        switch (class)
        {
            case CLASS::NONE:
                break;
            case CLASS::SCOUT:
                tclassname = TFCLASSNAMES::SCOUT;
                tmax_speed = SCOUT::MAXSPEED;
                tmax_strafe_speed = SCOUT::MAXSTRAFESPEED;
                tmax_armor_type = SCOUT::MAXARMORTYPE;
                tinit_armor_type = SCOUT::INITARMORTYPE;
                tinit_armor_classes = SCOUT::INITARMORCLASS;
                tillegal_bit = SCOUT::ILLEGALBIT;
                tweapon1 = SCOUT::WEAPON1;
                tweapon2 = SCOUT::WEAPON2;
                tweapon3 = SCOUT::WEAPON3;
                ttf_attributes = SCOUT::TF_ATTRIBUTES;
                tmax_shells = SCOUT::MAXAMMO_SHOT;
                tinit_shells = SCOUT::INITAMMO_SHOT;
                tmax_nails = SCOUT::MAXAMMO_NAIL;
                tinit_nails = SCOUT::INITAMMO_NAIL;
                tmax_rockets = SCOUT::MAXAMMO_ROCKET;
                tinit_rockets = SCOUT::INITAMMO_ROCKET;
                tmax_cells = SCOUT::MAXAMMO_CELL;
                tinit_cells = SCOUT::INITAMMO_CELL;
                ttype_gren1 = SCOUT::TYPE_GREN1;
                ttype_gren2 = SCOUT::TYPE_GREN2;
                
                switch (GameSettings.season)
                {
                    case SEASON::ONE:
                        tmax_health = SCOUT::MAXHEALTH_FO;
                        tmax_armor = SCOUT::MAXARMOR_FO;
                        tinit_armor = tmax_armor;
                        tmax_gren1 = SCOUT::MAXAMMO_GREN1;
                        tmax_gren2 = SCOUT::MAXAMMO_GREN2;
                        tinit_gren1 = tmax_gren1;
                        tinit_gren2 = tmax_gren2;
                        break;
                    case SEASON::FO:
                    case SEASON::TF28:
                        if (GameSettings.old_hp_armor)
                        {
                            tmax_health = SCOUT::MAXHEALTH;
                            tmax_armor = SCOUT::MAXARMOR;
                        }
                        else
                        {
                            tmax_health = SCOUT::MAXHEALTH_FO;
                            tmax_armor = SCOUT::MAXARMOR_FO;
                        }
                        tmax_gren1 = SCOUT::MAXAMMO_GREN1;
                        tmax_gren2 = SCOUT::MAXAMMO_GREN2;
                        tmax_shells = SCOUT::MAXAMMO_SHOT;
                        tmax_nails = SCOUT::MAXAMMO_NAIL;
                        tmax_rockets = SCOUT::MAXAMMO_ROCKET;
                        tmax_cells = SCOUT::MAXAMMO_CELL;

                        tinit_armor = tmax_armor / 2;
                        tinit_shells = SCOUT::INITAMMO_SHOT;
                        tinit_nails = SCOUT::INITAMMO_NAIL;
                        tinit_rockets = SCOUT::INITAMMO_ROCKET;
                        tinit_cells = SCOUT::INITAMMO_CELL;
                        tinit_gren1 = SCOUT::INITAMMO_GREN1;
                        tinit_gren2 = SCOUT::INITAMMO_GREN2;
                        break;
                }
                break;
            case CLASS::SOLDIER:
                tclassname = TFCLASSNAMES::SOLDIER;
                tmax_speed = SOLDIER::MAXSPEED;
                tmax_strafe_speed = SOLDIER::MAXSTRAFESPEED;
                tmax_armor_type = SOLDIER::MAXARMORTYPE;
                tinit_armor_type = SOLDIER::INITARMORTYPE;
                tinit_armor_classes = SOLDIER::INITARMORCLASS;
                tillegal_bit = SOLDIER::ILLEGALBIT;
                tweapon1 = SOLDIER::WEAPON1;
                tweapon2 = SOLDIER::WEAPON2;
                tweapon3 = SOLDIER::WEAPON3;
                tweapon4 = SOLDIER::WEAPON4;
                ttf_attributes = SOLDIER::TF_ATTRIBUTES;
                tmax_shells = SOLDIER::MAXAMMO_SHOT;
                tinit_shells = SOLDIER::INITAMMO_SHOT;
                tmax_nails = SOLDIER::MAXAMMO_NAIL;
                tinit_nails = SOLDIER::INITAMMO_NAIL;
                tmax_rockets = SOLDIER::MAXAMMO_ROCKET;
                tinit_rockets = SOLDIER::INITAMMO_ROCKET;
                tmax_cells = SOLDIER::MAXAMMO_CELL;
                tinit_cells = SOLDIER::INITAMMO_CELL;
                ttype_gren1 = SOLDIER::TYPE_GREN1;
                ttype_gren2 = SOLDIER::TYPE_GREN2;
                tmax_activegren2 = SOLDIER::MAX_ACTIVEGREN2;
                
                switch (GameSettings.season)
                {
                    case SEASON::ONE:
                        tmax_health = SOLDIER::MAXHEALTH_FO;
                        tmax_armor = SOLDIER::MAXARMOR_FO;
                        tinit_armor = tmax_armor;
                        tmax_gren1 = SOLDIER::MAXAMMO_GREN1;
                        tmax_gren2 = SOLDIER::MAXAMMO_GREN2;
                        tinit_gren1 = tmax_gren1;
                        tinit_gren2 = tmax_gren2;
                        break;
                    case SEASON::FO:
                    case SEASON::TF28:
                        if (GameSettings.old_hp_armor)
                        {
                            tmax_health = SOLDIER::MAXHEALTH;
                            tmax_armor = SOLDIER::MAXARMOR;
                        }
                        else
                        {
                            tmax_health = SOLDIER::MAXHEALTH_FO;
                            tmax_armor = SOLDIER::MAXARMOR_FO;
                        }
                        tmax_gren1 = SOLDIER::MAXAMMO_GREN1;
                        tmax_gren2 = SOLDIER::MAXAMMO_GREN2;
                        tmax_shells = SOLDIER::MAXAMMO_SHOT;
                        tmax_nails = SOLDIER::MAXAMMO_NAIL;
                        tmax_rockets = SOLDIER::MAXAMMO_ROCKET;
                        tmax_cells = SOLDIER::MAXAMMO_CELL;

                        tinit_armor = tmax_armor / 2;
                        tinit_shells = SOLDIER::INITAMMO_SHOT;
                        tinit_nails = SOLDIER::INITAMMO_NAIL;
                        tinit_rockets = SOLDIER::INITAMMO_ROCKET;
                        tinit_cells = SOLDIER::INITAMMO_CELL;
                        tinit_gren1 = SOLDIER::INITAMMO_GREN1;
                        tinit_gren2 = SOLDIER::INITAMMO_GREN2;
                        break;
                }
                break;
            case CLASS::DEMOMAN:
                tclassname = TFCLASSNAMES::DEMOMAN;
                tmax_speed = DEMOMAN::MAXSPEED;
                tmax_strafe_speed = DEMOMAN::MAXSTRAFESPEED;
                tmax_armor_type = DEMOMAN::MAXARMORTYPE;
                tinit_armor_type = DEMOMAN::INITARMORTYPE;
                tinit_armor_classes = DEMOMAN::INITARMORCLASS;
                tillegal_bit = DEMOMAN::ILLEGALBIT;
                tweapon1 = DEMOMAN::WEAPON1;
                tweapon2 = DEMOMAN::WEAPON2;
                tweapon3 = DEMOMAN::WEAPON3;
                tweapon4 = DEMOMAN::WEAPON4;
                ttf_attributes = DEMOMAN::TF_ATTRIBUTES;
                tmax_shells = DEMOMAN::MAXAMMO_SHOT;
                tinit_shells = DEMOMAN::INITAMMO_SHOT;
                tmax_nails = DEMOMAN::MAXAMMO_NAIL;
                tinit_nails = DEMOMAN::INITAMMO_NAIL;
                tmax_rockets = DEMOMAN::MAXAMMO_ROCKET;
                tinit_rockets = DEMOMAN::INITAMMO_ROCKET;
                tmax_cells = DEMOMAN::MAXAMMO_CELL;
                tinit_cells = DEMOMAN::INITAMMO_CELL;
                ttype_gren1 = DEMOMAN::TYPE_GREN1;
                ttype_gren2 = DEMOMAN::TYPE_GREN2;
                tmax_activegren2 = DEMOMAN::MAX_ACTIVEGREN2;
                
                switch (GameSettings.season)
                {
                    case SEASON::ONE:
                        tmax_health = DEMOMAN::MAXHEALTH_FO;
                        tmax_armor = DEMOMAN::MAXARMOR_FO;
                        tinit_armor = tmax_armor;
                        tmax_gren1 = DEMOMAN::MAXAMMO_GREN1;
                        tmax_gren2 = DEMOMAN::MAXAMMO_GREN2;
                        tinit_gren1 = tmax_gren1;
                        tinit_gren2 = tmax_gren2;
                        break;
                    case SEASON::FO:
                    case SEASON::TF28:
                        if (GameSettings.old_hp_armor)
                        {
                            tmax_health = DEMOMAN::MAXHEALTH;
                            tmax_armor = DEMOMAN::MAXARMOR;
                        }
                        else
                        {
                            tmax_health = DEMOMAN::MAXHEALTH_FO;
                            tmax_armor = DEMOMAN::MAXARMOR_FO;
                        }
                        tmax_gren1 = DEMOMAN::MAXAMMO_GREN1;
                        tmax_gren2 = DEMOMAN::MAXAMMO_GREN2;
                        tmax_shells = DEMOMAN::MAXAMMO_SHOT;
                        tmax_nails = DEMOMAN::MAXAMMO_NAIL;
                        tmax_rockets = DEMOMAN::MAXAMMO_ROCKET;
                        tmax_cells = DEMOMAN::MAXAMMO_CELL;

                        tinit_armor = tmax_armor / 2;
                        tinit_shells = DEMOMAN::INITAMMO_SHOT;
                        tinit_nails = DEMOMAN::INITAMMO_NAIL;
                        tinit_rockets = DEMOMAN::INITAMMO_ROCKET;
                        tinit_cells = DEMOMAN::INITAMMO_CELL;
                        tinit_gren1 = DEMOMAN::INITAMMO_GREN1;
                        tinit_gren2 = DEMOMAN::INITAMMO_GREN2;
                        break;
                }
                break;
        }

        switch (GameSettings.season)
        {
            case SEASON::FO:
            case SEASON::TF28:
                if (GameSettings.spawn_full)
                {
                    tinit_armor = tmax_armor;
                    tinit_shells = tmax_shells;
                    tinit_nails = tmax_nails;
                    tinit_rockets = tmax_rockets;
                    tinit_cells = tmax_cells;
                    tinit_gren1 = tmax_gren1;
                    tinit_gren2 = tmax_gren2;
                }
                break;
        }

        Classes[class-1].class = class;
        Classes[class-1].classname = tclassname;
        Classes[class-1].max_speed = tmax_speed;
        Classes[class-1].max_strafe_speed = tmax_strafe_speed;
        Classes[class-1].max_armor_type = tmax_armor_type;
        Classes[class-1].init_armor_type = tinit_armor_type;
        Classes[class-1].init_armor_classes = tinit_armor_classes;
        Classes[class-1].init_armor = tinit_armor;
        Classes[class-1].illegal_bit = tillegal_bit;
        Classes[class-1].weapon1 = tweapon1;
        Classes[class-1].weapon2 = tweapon2;
        Classes[class-1].weapon3 = tweapon3;
        Classes[class-1].weapon4 = tweapon4;
        Classes[class-1].tf_attributes = ttf_attributes;
        Classes[class-1].max_shells = tmax_shells;
        Classes[class-1].init_shells = tinit_shells;
        Classes[class-1].max_nails = tmax_nails;
        Classes[class-1].init_nails = tinit_nails;
        Classes[class-1].max_rockets = tmax_rockets;
        Classes[class-1].init_rockets = tinit_rockets;
        Classes[class-1].max_cells = tmax_cells;
        Classes[class-1].init_cells = tinit_cells;
        Classes[class-1].type_gren1 = ttype_gren1;
        Classes[class-1].type_gren2 = ttype_gren2;
        Classes[class-1].max_health = tmax_health;
        Classes[class-1].max_armor = tmax_armor;
        Classes[class-1].max_gren1 = tmax_gren1;
        Classes[class-1].max_gren2 = tmax_gren2;
        Classes[class-1].max_activegren2 = tmax_activegren2;
    };

    nonvirtual void () PopulateTeams =
    {
        // FIXME - this will be slow, needs to be a struct
        Teams = memalloc(sizeof(*Teams)*GameSettings.number_of_teams);
        for (float i = 1; i <= GameSettings.number_of_teams; i++)
        {
            team_c team = spawn(team_c, team_no: i);
            Teams[i-1] = team;
        }
    };

    /*
    ============
    IntermissionThink

    When the player presses attack or jump, change to the next level
    ============
    */
    nonvirtual void (player_c player) IntermissionThink =
    {
        if (time < this.intermission_exittime)
            return;

        if (!player.button0 && !player.button1 && !player.button2)
            return;
        
        this.GotoNextMap();
    };

    nonvirtual void () GotoNextMap =
    {
    //ZOID: 12-13-96, samelevel is overloaded, only 1 works for same level

        if (cvar("samelevel") == 1)     // if samelevel is set, stay on same level
            changelevel(mapname);
        else 
        {
            // configurable map lists, see if the current map exists as a
            // serverinfo/localinfo var
            string newmap = infokey(world, mapname);
            if (newmap != "")
                changelevel(newmap);
            else
                changelevel(nextmap);
        }
    };


    /*
    ============
    execute_changelevel

    The global "nextmap" has been set previously.
    Take the players to the intermission spot
    ============
    */
    nonvirtual void () ExecuteChangeLevel =
    {
        this.intermission_running = 1;
        
        // enforce a wait time before allowing changelevel
        this.intermission_exittime = time + 5;

        entity pos = FindIntermission();

        // play intermission music
        WriteByte (MSG_ALL, SVC_CDTRACK);
        WriteByte (MSG_ALL, 3);

        WriteByte (MSG_ALL, SVC_INTERMISSION);
        WriteCoord (MSG_ALL, pos.origin_x);
        WriteCoord (MSG_ALL, pos.origin_y);
        WriteCoord (MSG_ALL, pos.origin_z);
        WriteAngle (MSG_ALL, pos.mangle_x);
        WriteAngle (MSG_ALL, pos.mangle_y);
        WriteAngle (MSG_ALL, pos.mangle_z);
        
        other = find(world, ::classname, "player");
        while (other)
        {
            other.takedamage = DAMAGE_NO;
            other.solid = SOLID_NOT;
            other.movetype = MOVETYPE_NONE;
            other.modelindex = 0;
            other = find (other, ::classname, "player");
        }
    };

    /*
    ============
    FindIntermission

    Returns the entity to view from
    ============
    */
    nonvirtual entity () FindIntermission =
    {
        // look for info_intermission first
        entity spot = find (world, ::classname, "info_intermission");
        if (spot)
        {       // pick a random one
            float cyc = random() * 4;
            while (cyc > 1)
            {
                spot = find (spot, ::classname, "info_intermission");
                if (!spot)
                    spot = find (spot, ::classname, "info_intermission");
                cyc = cyc - 1;
            }
            return spot;
        }

        // then look for the start position
        spot = find (world, ::classname, "info_player_start");
        if (spot)
            return spot;
        
        objerror ("FindIntermission: no spot");
        return world;
    };

    nonvirtual void () NextLevel = 
    {
        if (nextmap != "")
            return; // already done

        entity o;
        if (mapname == "start")
        {
            if (!cvar("registered"))
            {
                mapname = "e1m1";
            }
            else if (!(serverflags & 1))
            {
                mapname = "e1m1";
                serverflags = serverflags | 1;
            }
            else if (!(serverflags & 2))
            {
                mapname = "e2m1";
                serverflags = serverflags | 2;
            }
            else if (!(serverflags & 4))
            {
                mapname = "e3m1";
                serverflags = serverflags | 4;
            }
            else if (!(serverflags & 8))
            {
                mapname = "e4m1";
                serverflags = serverflags - 7;
            }
    
            o = spawn();
            o.map = mapname;
        }
        else
        {
            // find a trigger changelevel
            o = find(world, ::classname, "trigger_changelevel");
            if (!o || mapname == "start")
            {       // go back to same map if no trigger_changelevel
                o = spawn();
                o.map = mapname;
            }
        }

        nextmap = o.map;

        if (o.nextthink < time)
        {
            o.think = this.ExecuteChangeLevel;
            o.nextthink = time + 0.1;
        }
    };

    nonvirtual void (player_c player) SendAliases =
    {
        if (player.has_aliases)
            return;

        for(float i = 0; i < Aliases.length; i++)
        {
            string cmd = Aliases[i].command;
            float imp = Aliases[i].impulse;
            float imp2 = Aliases[i].impulse2;
            AliasCommand(player, cmd, imp, imp2);
        }

        player.has_aliases = TRUE;
    };

    nonvirtual void (player_c player, string cmd, float imp, float imp2) AliasCommand =
    {
        string s = strcat("alias ", cmd, " \"impulse ", ftos(imp));
        if (imp2)
            s = strcat(s, "; wait; impulse ", ftos(imp2));
            
        s = strcat(s, "\"\n");

        stuffcmd(player, s);
    };

    nonvirtual void() CheckRules =
    {       
        if (timelimit && time >= timelimit)
            NextLevel();
        
        if (fraglimit && self.frags >= fraglimit)
            NextLevel();
    };
};
