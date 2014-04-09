/*
 * This file is part of OrdersAI.
 *
 * OrdersAI is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * OrdersAI is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with OrdersAI.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright 2014 James Anderson
 */

/** @file main.nut Implementation of OrdersAI, containing the main loop. */


import("util.superlib", "SuperLib", 38);


//SLVehicle <- SuperLib.Vehicle;
//Tile <- SuperLib.Tile
//GSIndustry <- AIIndustry
//Industry <- SuperLib.Industry

require("scheduler/scheduler.nut");
require("organizer/organizer.nut");
 
/**
 * The main class of OrdersAI.
 */
class OrdersAI extends AIController
{
/* private: */
 
	_pending_events = null;            ///< An array containing [EventType, value] pairs of unhandles events. 
	_vehicle_table = null;
	
/* public: */

	constructor()
	{
		::main_instance <- this; 
		
		/* Most of the initialization is done in Init, but we set some variables
		 * here so we can save them without checking for null. */
		this._pending_events = [];
		this._vehicle_table = null;
	}

	/**
	 * Initialize all 'global' variables. Since there is a limit on the time the constructor
	 * can take we don't do this in the constructor.
	 */
	function Init();
 
	/**
	 * Get all events from AIEventController and store them in an
	 *   in an internal array.
	 */
	function GetEvents();
	
	
	/**
	 * Ensure all vehicles have valid orders
	 */
	function CheckVehicles();
 
	/**
	 * Handle all pending events. Events are stored internal in the _pending_events
	 *  array as [AIEventType, value] pair. The value that is saved depends on the
	 *  events. For example, for AI_ET_INDUSTRY_CLOSE the IndustryID is saved in value.
	 */
	function HandleEvents();
 
	/**
	 * The mainloop.
	 * @note This is called by OpenTTD, no need to call from within the AI.
	 */
	function Start();
	
	function Save();
	
	function Load(version, data);
	
	
 
};

function OrdersAI::BuildableTileNearMapCenter()
{
	local startX = AIMap.GetMapSizeX() / 2
	local startY = AIMap.GetMapSizeY() / 2
	
	local candidate = AIMap.GetTileIndex(startX, startY) 
	while(!AITile.IsBuildable(candidate))
	{
		AILog.Info("Checking for buildable tile at " + startX + "," + startY)
		startX -= 1
		if(startX < 0)
		{
			startX = AIMap.GetMapSizeX() / 2
			startY -= 1
		}
		
		candidate = AIMap.GetTileIndex(startX, startY)
	}
	
	return candidate 	
}

function OrdersAI::_InfoSignCreated()
{ 
	foreach(sign, _ in AISignList()) 
	{
		if(AISign.GetLocation() == OrdersAI.MapCenter())
			return true
	}
	
	return false
}

function OrdersAI::CreateInfoSign()
{
	if(OrdersAI._InfoSignCreated())
		return
		
	local InfoText = "Welcome to Orders Assistance AI.  I'm happy to route your vehicles for you, but we need to be on the same team.\nCurrently this is done by opening the CTRL+ALT+C window and changing your team number.  Save and reload if you want multiplayer."
	
	local signtile = OrdersAI.BuildableTileNearMapCenter()
	
	if(!AISign.BuildSign(signtile, InfoText))
		throw (AIError.GetLastErrorString())
	
	return 	
}


function OrdersAI::Init()
{	
	AILog.Info("Init Starting")
	OrdersAI.CreateManualGroups()
	//OrdersAI.CreateInfoSign()
	AILog.Info("Init Complete")
	
	//Organizer.AssignVehiclesToGroups()
	return
}

function OrdersAI::Save() {
	return { 
	};
}

//function OrdersAI::Load(version, data) {
//}



function OrdersAI::CreateManualGroups()
{
	/*Create groups to give users hints about how to place units under manual control*/
	
	//VT_RAIL 	 Rail type vehicle.
	//VT_ROAD 	 Road type vehicle (bus / truck).
	//VT_WATER 	 Water type vehicle.
	//VT_AIR 	 Air type vehicle.
	
	local ManualGroupName = "Human Controlled"
	
	Organizer.GetOrCreateGroup(AIVehicle.VT_ROAD, ManualGroupName + " vehicles")
	Organizer.GetOrCreateGroup(AIVehicle.VT_RAIL, ManualGroupName + " trains")
	Organizer.GetOrCreateGroup(AIVehicle.VT_WATER, ManualGroupName + " vessels")
	Organizer.GetOrCreateGroup(AIVehicle.VT_AIR, ManualGroupName + " aircraft")
}
 

function OrdersAI::GetEvents()
{
	while (AIEventController.IsEventWaiting()) {
		local e = AIEventController.GetNextEvent();
		switch (e.GetEventType()) {				
			case AIEvent.AIEventVehicleWaitingInDepot:
				//Organizer.AssignVehicleToGroup(e.GetVehicleID());
				break; 
		}
	}
}
 
function OrdersAI::HandleEvents()
{
	foreach (event_pair in this._pending_events) {
		switch (event_pair[0]) {
			case AIEvent.AI_ET_INDUSTRY_CLOSE:
				//this._truck_manager.IndustryClose(event_pair[1]);
				//this._train_manager.IndustryClose(event_pair[1]);
				break;

			case AIEvent.AI_ET_INDUSTRY_OPEN:
				//this._truck_manager.IndustryOpen(event_pair[1]);
				//this._train_manager.IndustryOpen(event_pair[1]);
				break;
		}
	}
	this._pending_events = [];
}

function OrdersAI::CheckVehicles()
{
	local knownVehicleIDs = [];
	local vehicle_list = AIVehicleList();
	
	foreach(vehicle, _ in vehicle_list)
	{ 
		if(Organizer.VehicleIsUserManaged(vehicle)) {
			continue;
		}
		
		local routeupdate = Scheduler.CheckOrders(vehicle);
		
		if(routeupdate)
			Organizer.AssignVehicleToGroup(vehicle);
			
		//AILog.Info();
	}	
}

function OrdersAI::Start()
{
	/* Check if the names of some settings are valid. Of course this isn't
	 * completely failsafe, as the meaning could be changed but not the name,
	 * but it'll catch some problems. */
	
	/* Call our real constructor here to prevent 'is taking too long to load' errors. */
	this.Init();
	
	//local start_tick = AIController.GetTick();

	/* Before starting the main loop, sleep a bit to prevent problems with ecs */
	//AIController.Sleep(max(1, 260 - (AIController.GetTick() - start_tick)));
	while(1) {
		local start_tick = AIController.GetTick(); 
		this.CheckVehicles();
		local ticks_used = AIController.GetTick() - start_tick;
		
		AILog.Info("****** Ticks used to route vehicles: " + ticks_used.tostring() + " with " + AIController.GetOpsTillSuspend().tostring() + " ops remaining ******")
		
		//AIController.Sleep(10);
	}
}
