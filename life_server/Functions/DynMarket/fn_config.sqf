/*
##################### DYNAMIC MARKET SCRIPT #####################
### AUTHOR: RYAN TT.                                          ###
### STEAM: www.steamcommunity.com/id/ryanthett                ###
###                                                           ###
### DISCLAIMER: THIS SCRIPT CAN BE USED ON EVERY SERVER ONLY  ###
###             WITH THIS HEADER / NOTIFICATION               ###
#################################################################
*/

// ███████████████████████████████████████████████████████████████████████
// █████████████████ DYNAMIC MARKET BASIC CONFIGURATION ██████████████████
// ███████████████████████████████████████████████████████████████████████

DYNMARKET_Serveruptime         = 05;   // Serveruptime after restart in hours
DYNMARKET_UseExternalDatabase  = true; // Should the script use the External Database?
DYNMARKET_PriceUpdateInterval  = 01;   // After how many minutes should the price be updated?
DYNMARKET_CreateBackups        = true; // Should the server save write the prices regulary into the Database? If false, it will save the prices before Server-restart?
DYNMARKET_CreateBackupInterval = 03;   // After how many updates (PriceUpdateIntervals) should the prices be saved into the Database?
DYNMARKET_UserNotification     = false; // Should the user be informed with a hint whenever the prices got updated?

// █████████████████ USER NOTIFICATION TEXTS  █████████████████

DYNMARKET_UserNotification_Text = 
[
	"Your prices have been updated!",
	"The new prices are being calculated by the server..."
];

// █████████████████ ITEM GROUP CONFIGURATION █████████████████

DYNMARKET_Items_Groups =
[
	["Food",
		[
			/*["아이템 코드",-1,최소,최대],*/
			//Food
			["apple",-1,100,500],
			["peach",-1,100,500],
			["rawMilk",-1,100,1300],
			["milk",-1,1000,6200]
			//Mined
		],
		0.8
	],
	["Fish",
		[
			["salema_raw",-1,500,3450],
			["salema",-1,1000,4300],
			["ornate_raw",-1,450,3450],
			["ornate",-1,1000,4000],
			["mackerel_raw",-1,1000,4000],
			["mackerel",-1,1500,4500],
			["tuna_raw",-1,3500,6500],
			["tuna",-1,4000,8000],
			["mullet_raw",-1,1000,5000],
			["mullet",-1,1300,5300],
			["catshark_raw",-1,6000,10000],
			["catshark",-1,7000,11000]
		],
		0.8
	],
	["Animal",
		[
			["rabbit_raw",-1,1000,4000],
			["rabbit",-1,2000,6000],
			["hen_raw",-1,3000,7000],
			["hen",-1,4000,8000],
			["rooster_raw",-1,15000,45000],
			["rooster",-1,17000,47000],
			["sheep_raw",-1,60000,90000],
			["sheep",-1,62000,92000],
			["goat_raw",-1,70000,100000],
			["goat",-1,72000,102000]
		],
		0.8
	],
	["Mined",
		[
			["wood",-1,800,3800],
			["plywood",-1,2500,6500],
			["oil_unprocessed",-1,1000,4000],
			["oil_processed",-1,1200,5200],
			["copper_refined",-1,600,4600],
			["iron_refined",-1,2300,6300],
			["salt_refined",-1,500,3500],
			["glass",-1,1500,5500],
			["diamond_uncut",-1,1000,5000],
			["diamond_cut",-1,4100,8100],
			["cement",-1,1400,5400]
		],
		0.8
	],
	["Illegal", 
		[
			/*["아이템 코드",-1,최소,최대],*/
			["heroin_processed",-1,4000,12000],
			["marijuana",-1,2800,10800],
			["cocaine_processed",-1,5000,13000],
			["turtle_raw",-1,20000,50000],
			["turtle_soup",-1,25000,55000]
		],
		0.6
	]
];

// █████████████████    ALL SELLABLE ITEMS    █████████████████

DYNMARKET_Items_ToTrack        = 
[
	/* ["아이템코드",기본가격], */
	//Food
	["apple",300],
	["peach",300],
	["rawMilk",700],
	["milk",4200],
	//Fish
	["salema_raw",1450],
	["salema",2300],
	["ornate_raw",1450],
	["ornate",2000],
	["mackerel_raw",2000],
	["mackerel",2500],
	["tuna_raw",5500],
	["tuna",6000],
	["mullet_raw",3000],
	["mullet",3300],
	["catshark_raw",8000],
	["catshark",9000],
	//Animal
	["rabbit_raw",2000],
	["rabbit",4000],
	["hen_raw",5000],
	["hen",6000],
	["rooster_raw",25000],
	["rooster",27000],
	["sheep_raw",70000],
	["sheep",72000],
	["goat_raw",80000],
	["goat",82000],
	//Mined
	["wood",1800],
	["plywood",4500],
	["oil_unprocessed",2000],
	["oil_processed",3200],
	["copper_refined",2600],
	["iron_refined",4300],
	["salt_refined",1500],
	["glass",3500],
	["diamond_uncut",3000],
	["diamond_cut",6100],
	["cement",3400],
	//Illegal
	["heroin_processed",8000],
	["marijuana",6800],
	["cocaine_processed",9000],
	["turtle_raw",30000],
	["turtle_soup",45000]
];

//███████████████████████████████████████████████████████████████████████
//██████████████████ DO NOT MODIFY THE FOLLOWING CODE! ██████████████████
//███████████████████████████████████████████████████████████████████████

DYNMARKET_Items_CurrentPriceArr = [];
DYNMARKET_sellarraycopy = DYNMARKET_Items_ToTrack;
DYNMARKET_Serveruptime = (DYNMARKET_Serveruptime * 3600) - 300;
{
	_currentArray = _x;
	DYNMARKET_Items_CurrentPriceArr pushBack [_currentArray select 0,_currentArray select 1,0];
} forEach DYNMARKET_Items_ToTrack;
publicVariable "DYNMARKET_UserNotification";
publicVariable "DYNMARKET_UserNotification_Text";
if (DYNMARKET_UseExternalDatabase) then {[1] call TON_fnc_HandleDB;};
DYNMARKET_UpdateCount = 0;
if (DYNMARKET_UseExternalDatabase) then {
	[] spawn {
		sleep DYNMARKET_Serveruptime;
		diag_log "### DYNMARKET >> CURRENT PRICES ARE BEING WRITTEN TO THE DATABASE    ###";
		diag_log "### DYNMARKET >> AS PLANNED, AWAITING RESULT...                      ###";
		[0] call TON_fnc_HandleDB;
	};
};
sleep 5;
[] call TON_fnc_sleeper;
