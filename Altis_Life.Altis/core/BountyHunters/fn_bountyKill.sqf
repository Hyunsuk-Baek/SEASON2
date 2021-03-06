#include "..\..\script_macros.hpp"
/*
    File: fn_bountyKill.sqf
    Author: !TS JORDAN
	Originally Made for: Underbelly ArmA 

    Description:
    Removes the bounty on a selected player.
*/
private ["_display","_list"];
disableSerialization;
if !(license_civ_bountyH) exitWith {hint "현상금 사냥꾼만이 사람의 목숨이 달린 [현상금]을 제거할 수 있습니다!"};
_display = findDisplay 24000;
_list = _display displayCtrl 24020;
_data = lbData[24010,(lbCurSel 24010)];
_data = call compile format ["%1", _data];
if (isNil "_data") exitWith {};
if (!(_data isEqualType [])) exitWith {};
if (_data isEqualTo []) exitWith {};
private _remover = getPlayerUID player;
private _removed = _data select 0;

if (_remover isEqualTo _removed) exitWith {hint "당신은 현상금 사냥꾼 명단에서 자신을 제거할 수 없습니다! 지우려면 죽어야만 합니다!"};


if (life_HC_isActive) then {
    [(_data select 0)] remoteExecCall ["HC_fnc_bountyRemove",HC_Life];
} else {
    [(_data select 0)] remoteExecCall ["life_fnc_bountyRemove",RSERV];
};
