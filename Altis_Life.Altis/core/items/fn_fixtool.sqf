titleText ["Fixing buildings","PLAIN DOWN"];titleFadeOut 2;
_repair = (getPosATL player) nearObjects ["Building", 100];
_fix=0;
_break=1;
{_x setDammage _fix} forEach _repair;