#include "..\..\script_macros.hpp"
/*
    File: fn_jailMe.sqf
    Author Bryan "Tonic" Boardwine

    Description:
    Once word is received by the server the rest of the jail execution is completed.
*/
private ["_time","_bail","_esc","_countDown"];

params [
 ["_ret",[],[[]]],
 ["_bad",false,[false]],
 ["_time",15,[0]]
];
//디컨한놈 남은 시간 * 2 
if (_bad) then { _time = time + ( 2 * _time * 60); } else { _time = time + (_time * 60); };

if (count _ret > 0) then { life_bail_amount = (_ret select 2); } else { life_bail_amount = 50000; };
_esc = false;
_bail = false;

if(_time <= 0) then { 
    _time = time + (10 * 60);
    hintC "어드민에게 이 화면 캡쳐후 신고하세요 : 구속시간이 오류라서 10분으로 세팅합니다.";
};

[_bad, _time] spawn {
    life_canpay_bail = false;
    life_bail_amount = life_bail_amount * 1;
    if (_this select 0) then {
        sleep ( (_this select 1) * 0.5 );
    } else {
        sleep ( (_this select 1) * 0.2 );
    };
    life_canpay_bail = true;
};

life_oldClothes = uniform player;
if (!(player isUniformAllowed "mgsr_civ_01_uniform")) then {
    player forceAddUniform "mgsr_civ_01_uniform";
} else {
    player addUniform "mgsr_civ_01_uniform";
};

for "_i" from 0 to 1 step 0 do {
    if ((round(_time - time)) > 0) then {
        _countDown = [(_time - time),"MM:SS.MS"] call BIS_fnc_secondsToString;
        hintSilent parseText format [(localize "STR_Jail_Time")+ "<br/> <t size='2'><t color='#FF0000'>%1</t></t><br/><br/>" +(localize "STR_Jail_Pay")+ " %3<br/>" +(localize "STR_Jail_Price")+ " $%2",_countDown,[life_bail_amount] call life_fnc_numberText,if (life_canpay_bail) then {"Yes"} else {"No"}];
    };

    if (LIFE_SETTINGS(getNumber,"jail_forceWalk") isEqualTo 1) then {
        player forceWalk true;
    };

    player allowDamage false;
	
    private _escDist = [[["Altis", 60], ["Tanoa", 145], ["Jackson_County", 80]]] call TON_fnc_terrainSort;

    if (player distance (getMarkerPos "jail_marker") > _escDist) exitWith {
        _esc = true;
    };

    if (life_bail_paid) exitWith {
        _bail = true;
    };

    if ((round(_time - time)) < 1) exitWith {hint ""};
    if (!alive player && ((round(_time - time)) > 0)) exitWith {};
    sleep 0.1;
};


switch (true) do {
    case (_bail): {
        life_is_arrested = false;
        life_bail_paid = false;

        hint localize "STR_Jail_Paid";
        player setPos (getMarkerPos "jail_release");

        if (life_HC_isActive) then {
            [getPlayerUID player] remoteExecCall ["HC_fnc_wantedRemove",HC_Life];
        } else {
            [getPlayerUID player] remoteExecCall ["life_fnc_wantedRemove",RSERV];
        };
		
        removeUniform player;
        player addUniform life_oldClothes;
    };

    case (_esc): {
        life_is_arrested = false;
        hint localize "STR_Jail_EscapeSelf";
        [0,"STR_Jail_EscapeNOTF",true,[profileName]] remoteExecCall ["life_fnc_broadcast",RCLIENT];

        if (life_HC_isActive) then {
            [getPlayerUID player,profileName,"901"] remoteExecCall ["HC_fnc_wantedAdd",HC_Life];
        } else {
            [getPlayerUID player,profileName,"901"] remoteExecCall ["life_fnc_wantedAdd",RSERV];
        };
		
		      if (!(player isUniformAllowed "mgsr_robe_dirty")) then {
            player forceAddUniform "mgsr_robe_dirty";
        } else {
            player addUniform "mgsr_robe_dirty";
        };
    };

    case (alive player && !_esc && !_bail): {
        life_is_arrested = false;
        hint localize "STR_Jail_Released";

        if (life_HC_isActive) then {
            [getPlayerUID player] remoteExecCall ["HC_fnc_wantedRemove",HC_Life];
        } else {
            [getPlayerUID player] remoteExecCall ["life_fnc_wantedRemove",RSERV];
        };

        player setPos (getMarkerPos "jail_release");

		      removeUniform player;
        player addUniform life_oldClothes;
    };
};
[5] call SOCK_fnc_updatePartial;
[3] call SOCK_fnc_updatePartial;
player forceWalk false; // Enable running & jumping
player allowDamage true;