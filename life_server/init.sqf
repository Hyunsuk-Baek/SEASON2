#include "script_macros.hpp"
/*
    File: init.sqf
    Author: Bryan "Tonic" Boardwine

    Edit: Nanou for HeadlessClient optimization.
    Please read support for more informations.

    Description:
    Initialize the server and required systems.
*/
private ["_dome","_rsb","_timeStamp"];
DB_Async_Active = false;
DB_Async_ExtraLock = false;
life_server_isReady = false;
life_server_extDB_notLoaded = "";
serv_sv_use = [];
publicVariable "life_server_isReady";
life_save_civilian_position = if (LIFE_SETTINGS(getNumber,"save_civilian_position") isEqualTo 0) then {false} else {true};
fn_whoDoneIt = compile preprocessFileLineNumbers "\life_server\Functions\Systems\fn_whoDoneIt.sqf";

/*
    Prepare the headless client.
*/
life_HC_isActive = false;
publicVariable "life_HC_isActive";
HC_Life = false;
publicVariable "HC_Life";

if (EXTDB_SETTING(getNumber,"HeadlessSupport") isEqualTo 1) then {
    [] execVM "\life_server\initHC.sqf";
};

/*
    Prepare extDB before starting the initialization process
    for the server.
*/

if (isNil {uiNamespace getVariable "life_sql_id"}) then {
    life_sql_id = round(random(9999));
    CONSTVAR(life_sql_id);
    uiNamespace setVariable ["life_sql_id",life_sql_id];
        try {
        _result = EXTDB format ["9:ADD_DATABASE:%1",EXTDB_SETTING(getText,"DatabaseName")];
        if (!(_result isEqualTo "[1]")) then {throw "extDB2: Error with Database Connection"};
        _result = EXTDB format ["9:ADD_DATABASE_PROTOCOL:%2:SQL_RAW_V2:%1:ADD_QUOTES",FETCH_CONST(life_sql_id),EXTDB_SETTING(getText,"DatabaseName")];
        if (!(_result isEqualTo "[1]")) then {throw "extDB2: Error with Database Connection"};
    } catch {
        diag_log _exception;
        life_server_extDB_notLoaded = [true, _exception];
    };
    publicVariable "life_server_extDB_notLoaded";
    if (life_server_extDB_notLoaded isEqualType []) exitWith {};
    EXTDB "9:LOCK";
    diag_log "extDB2: Connected to Database";
} else {
    life_sql_id = uiNamespace getVariable "life_sql_id";
    CONSTVAR(life_sql_id);
    diag_log "extDB2: Still Connected to Database";
};

if (life_server_extDB_notLoaded isEqualType []) exitWith {};

/* Run stored procedures for SQL side cleanup */
["CALL resetLifeVehicles",1] call DB_fnc_asyncCall;
["CALL deleteDeadVehicles",1] call DB_fnc_asyncCall;
["CALL deleteOldHouses",1] call DB_fnc_asyncCall;
["CALL deleteOldGangs",1] call DB_fnc_asyncCall;

_timeStamp = diag_tickTime;
diag_log "----------------------------------------------------------------------------------------------------";
diag_log "---------------------------------- Starting Altis Life Server Init ---------------------------------";
diag_log "------------------------------------------ Version 5.0.0 -------------------------------------------";
diag_log "----------------------------------------------------------------------------------------------------";

if (LIFE_SETTINGS(getNumber,"save_civilian_position_restart") isEqualTo 1) then {
    [] spawn {
        _query = "UPDATE players SET civ_alive = '0' WHERE civ_alive = '1'";
        [_query,1] call DB_fnc_asyncCall;
    };
};

/* Map-based server side initialization. */
master_group attachTo[bank_obj,[0,0,0]];

{
    _hs = createVehicle ["Land_Hospital_main_F", [0,0,0], [], 0, "NONE"];
    _hs setDir (markerDir _x);
    _hs setPosATL (getMarkerPos _x);
    _var = createVehicle ["Land_Hospital_side1_F", [0,0,0], [], 0, "NONE"];
    _var attachTo [_hs, [4.69775,32.6045,-0.1125]];
    detach _var;
    _var = createVehicle ["Land_Hospital_side2_F", [0,0,0], [], 0, "NONE"];
    _var attachTo [_hs, [-28.0336,-10.0317,0.0889387]];
    detach _var;
    if (worldName isEqualTo "Tanoa") then {
        if (_forEachIndex isEqualTo 0) then {
            atm_hospital_2 setPos (_var modelToWorld [4.48633,0.438477,-8.25683]);
            vendor_hospital_2 setPos (_var modelToWorld [4.48633,0.438477,-8.25683]);
            "medic_spawn_3" setMarkerPos (_var modelToWorld [8.01172,-5.47852,-8.20022]);
            "med_car_2" setMarkerPos (_var modelToWorld [8.01172,-5.47852,-8.20022]);
            hospital_assis_2 setPos (_hs modelToWorld [0.0175781,0.0234375,-0.231956]);
        } else {
            atm_hospital_3 setPos (_var modelToWorld [4.48633,0.438477,-8.25683]);
            vendor_hospital_3 setPos (_var modelToWorld [4.48633,0.438477,-8.25683]);
            "medic_spawn_1" setMarkerPos (_var modelToWorld [-1.85181,-6.07715,-8.24944]);
            "med_car_1" setMarkerPos (_var modelToWorld [5.9624,11.8799,-8.28493]);
            hospital_assis_2 setPos (_hs modelToWorld [0.0175781,0.0234375,-0.231956]);
        };
    };
} forEach ["hospital_2","hospital_3"];

{
    if (!isPlayer _x) then {
        _npc = _x;
        {
            if (_x != "") then {
                _npc removeWeapon _x;
            };
        } forEach [primaryWeapon _npc,secondaryWeapon _npc,handgunWeapon _npc];
    };
} forEach allUnits;

[8,true,12] execFSM "\life_server\FSM\timeModule.fsm";

life_adminLevel = 0;
life_medicLevel = 0;
life_copLevel = 0;
CONST(JxMxE_PublishVehicle,"false");

/* Setup radio channels for west/independent/civilian */
/*
life_radio_west = radioChannelCreate [[0, 0.95, 1, 0.8], "Side Channel", "%UNIT_NAME", []];
life_radio_civ = radioChannelCreate [[0, 0.95, 1, 0.8], "Side Channel", "%UNIT_NAME", []];
life_radio_indep = radioChannelCreate [[0, 0.95, 1, 0.8], "Side Channel", "%UNIT_NAME", []];
*/
life_radio_west = radioChannelCreate [[255, 0, 0, 0.8], "EmergencyChannel", "%UNIT_NAME", []];
life_radio_indep = radioChannelCreate [[255, 0, 0, 0.8], "EmergencyChannel", "%UNIT_NAME", []];

/* Set the amount of gold in the federal reserve at mission start */
fed_bank setVariable ["safe",count playableUnits,true];
[] spawn TON_fnc_federalUpdate;

/* Event handler for disconnecting players */
addMissionEventHandler ["HandleDisconnect",{_this call TON_fnc_clientDisconnect; false;}];
[] call compile preprocessFileLineNumbers "\life_server\functions.sqf";

/* Set OwnerID players for Headless Client */
TON_fnc_requestClientID =
{
    (_this select 1) setVariable ["life_clientID", owner (_this select 1), true];
};
"life_fnc_RequestClientId" addPublicVariableEventHandler TON_fnc_requestClientID;

/* Event handler for logs */
"money_log" addPublicVariableEventHandler {diag_log (_this select 1)};
"advanced_log" addPublicVariableEventHandler {diag_log (_this select 1)};

/* Miscellaneous mission-required stuff */
life_wanted_list = [];

cleanupFSM = [] execFSM "\life_server\FSM\cleanup.fsm";

[] spawn {
    for "_i" from 0 to 1 step 0 do {
        uiSleep (30 * 60);
        {
            _x setVariable ["sellers",[],true];
        } forEach [Dealer_1];
    };
};

[] spawn TON_fnc_initHouses;
cleanup = [] spawn TON_fnc_cleanup;

TON_fnc_playtime_values = [];
TON_fnc_playtime_values_request = [];

//Just incase the Headless Client connects before anyone else
publicVariable "TON_fnc_playtime_values";
publicVariable "TON_fnc_playtime_values_request";


/* Setup the federal reserve building(s) */
private _vaultHouse = [[["Altis", "Land_Research_house_V1_F"], ["Tanoa", "Land_Medevac_house_V1_F"], ["Jackson_County", "Land_Research_house_V1_F"]]] call TON_fnc_terrainSort;
private _altisArray = [16019.5,16952.9,0];
private _tanoaArray = [11074.2,11501.5,0.00137329];
private _jacksonArray = [5600.56,232.659,0.665315];
private _pos = [[["Altis", _altisArray], ["Tanoa", _tanoaArray], ["Jackson_County", _jacksonArray]]] call TON_fnc_terrainSort;

_dome = nearestObject [_pos,"Land_Dome_Big_F"];
_rsb = nearestObject [_pos,_vaultHouse];

for "_i" from 1 to 3 do {_dome setVariable [format ["bis_disabled_Door_%1",_i],1,true]; _dome animate [format ["Door_%1_rot",_i],0];};
_dome setVariable ["locked",true,true];
_rsb setVariable ["locked",true,true];
_rsb setVariable ["bis_disabled_Door_1",1,true];
_dome allowDamage false;
_rsb allowDamage false;

/* Tell clients that the server is ready and is accepting queries */
life_server_isReady = true;
publicVariable "life_server_isReady";

/* Initialize hunting/fishing zone(s) */
aiSpawn = ["hunting_zone",40] spawn TON_fnc_huntingZone;
aiSpawn2 = ["fishing_zone",50] spawn TON_fnc_fishingZone;
aiSpawn3 = ["fishing_zone2",50] spawn TON_fnc_fishingZone2;

// We create the attachment point to be used for objects to attachTo load virtually in vehicles.
life_attachment_point = "Land_HelipadEmpty_F" createVehicle [0,0,0];
life_attachment_point setPosASL [0,0,0];
life_attachment_point setVectorDirAndUp [[0,1,0], [0,0,1]];

// Sharing the point of attachment with all players.
publicVariable "life_attachment_point";

//Map Object Delete by AOS
_markername1="del_obj_1";
_terrainobjects1=nearestTerrainObjects [(getMarkerPos _markername1),[],(getmarkersize _markername1)select 0];
{hideObjectGlobal _x} foreach _terrainobjects1;

_markername2="del_obj_2";
_terrainobjects2=nearestTerrainObjects [(getMarkerPos _markername2),[],(getmarkersize _markername2)select 0];
{hideObjectGlobal _x} foreach _terrainobjects2;

_markername3="del_obj_3";
_terrainobjects3=nearestTerrainObjects [(getMarkerPos _markername3),[],(getmarkersize _markername3)select 0];
{hideObjectGlobal _x} foreach _terrainobjects3;

_markername4="del_obj_4";
_terrainobjects4=nearestTerrainObjects [(getMarkerPos _markername4),[],(getmarkersize _markername4)select 0];
{hideObjectGlobal _x} foreach _terrainobjects4;

_markername5="del_obj_5";
_terrainobjects5=nearestTerrainObjects [(getMarkerPos _markername5),[],(getmarkersize _markername5)select 0];
{hideObjectGlobal _x} foreach _terrainobjects5;

_markername6="del_obj_6";
_terrainobjects6=nearestTerrainObjects [(getMarkerPos _markername6),[],(getmarkersize _markername6)select 0];
{hideObjectGlobal _x} foreach _terrainobjects6;

_markername7="del_obj_7";
_terrainobjects7=nearestTerrainObjects [(getMarkerPos _markername7),[],(getmarkersize _markername7)select 0];
{hideObjectGlobal _x} foreach _terrainobjects7;

_markername8="del_obj_8";
_terrainobjects8=nearestTerrainObjects [(getMarkerPos _markername8),[],(getmarkersize _markername8)select 0];
{hideObjectGlobal _x} foreach _terrainobjects8;

_markername9="del_obj_9";
_terrainobjects9=nearestTerrainObjects [(getMarkerPos _markername9),[],(getmarkersize _markername9)select 0];
{hideObjectGlobal _x} foreach _terrainobjects9;

_markername10="del_obj_10";
_terrainobjects10=nearestTerrainObjects [(getMarkerPos _markername10),[],(getmarkersize _markername10)select 0];
{hideObjectGlobal _x} foreach _terrainobjects10;

_markername11="del_obj_11";
_terrainobjects11=nearestTerrainObjects [(getMarkerPos _markername11),[],(getmarkersize _markername11)select 0];
{hideObjectGlobal _x} foreach _terrainobjects11;

_markername12="del_obj_12";
_terrainobjects12=nearestTerrainObjects [(getMarkerPos _markername12),[],(getmarkersize _markername12)select 0];
{hideObjectGlobal _x} foreach _terrainobjects12;

_markername13="del_obj_13";
_terrainobjects13=nearestTerrainObjects [(getMarkerPos _markername13),[],(getmarkersize _markername13)select 0];
{hideObjectGlobal _x} foreach _terrainobjects13;

_markername14="del_obj_14";
_terrainobjects14=nearestTerrainObjects [(getMarkerPos _markername14),[],(getmarkersize _markername14)select 0];
{hideObjectGlobal _x} foreach _terrainobjects14;

_markername15="del_obj_15";
_terrainobjects15=nearestTerrainObjects [(getMarkerPos _markername15),[],(getmarkersize _markername15)select 0];
{hideObjectGlobal _x} foreach _terrainobjects15;

_markername16="del_obj_16";
_terrainobjects16=nearestTerrainObjects [(getMarkerPos _markername16),[],(getmarkersize _markername16)select 0];
{hideObjectGlobal _x} foreach _terrainobjects16;

_markername17="del_obj_17";
_terrainobjects17=nearestTerrainObjects [(getMarkerPos _markername17),[],(getmarkersize _markername17)select 0];
{hideObjectGlobal _x} foreach _terrainobjects17;

_markername18="del_obj_18";
_terrainobjects18=nearestTerrainObjects [(getMarkerPos _markername18),[],(getmarkersize _markername18)select 0];
{hideObjectGlobal _x} foreach _terrainobjects18;

diag_log "----------------------------------------------------------------------------------------------------";
diag_log format ["               End of Altis Life Server Init :: Total Execution Time %1 seconds ",(diag_tickTime) - _timeStamp];
diag_log "----------------------------------------------------------------------------------------------------";
