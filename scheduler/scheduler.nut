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
 
import("util.superlib", "SuperLib", 37);


require("stationmanager.nut")

SLStation <- SuperLib.Station; 
SLHelper <- SuperLib.Helper;
SLVehicle <- SuperLib.Vehicle


class Scheduler
{
	static LastStationForVehicle = {}
	static OrderHistoryLength = 3
	
	static function CheckOrders(vehicle);
	
	static function GetVehicleStationType(vehicle); 
	
	static function RouteToNextPickup(vehicle);
	
	static function DispatchToStation(vehicle, station, flags);
	
	static function ClearVehicleOrders(vehicle);
	
};

/* Returns the station type for the vehicle */
function Scheduler::GetVehicleStationType(vehicle)
{ 
	switch(AIVehicle.GetVehicleType(vehicle))
	{
		case AIVehicle.VT_WATER:
			return AIStation.STATION_DOCK;
		case AIVehicle.VT_RAIL:
			return AIStation.STATION_TRAIN;
		case AIVehicle.VT_AIR:
			return AIStation.STATION_AIRPORT;
		case AIVehicle.VT_ROAD:
			if(SLHelper.GetPAXCargo() == SLVehicle.GetVehicleCargoType(vehicle))
				return AIStation.STATION_BUS_STOP;
			else
				return AIStation.STATION_TRUCK_STOP; 
	}
		
	return AIStation.STATION_ANY;
}


function Scheduler::CargoProducedAndAcceptedAtSameStation(cargotype)
{
	/*returns true if the stations supply and accept the same cargo, for example passengers and mail. 
	  When this is true we always route to pickups and do not use delivery routing
	  */
	if(SLHelper.GetPAXCargo() == cargotype)
		return true
		
	if(SLHelper.GetMailCargo() == cargotype)
		return true
	
	return false;
}


function Scheduler::NeedsRouteUpdate(vehicle)
{
	/*Return true if the vehicle needs to be given new orders*/
	if(AIVehicle.GetState(vehicle) == AIVehicle.VS_IN_DEPOT)
		//Don't mess with vehicles in depot.  This allows players the chance to move them into a group and issue orders manually
		return false; 
	
	local VehicleOrderCount = AIOrder.GetOrderCount(vehicle)
	if(VehicleOrderCount == 0)
		return true; 
		
	if(AIVehicle.GetState(vehicle) == AIVehicle.VS_AT_STATION && VehicleOrderCount <= Scheduler.OrderHistoryLength)
		return true; 
	
	if(!AIOrder.IsValidVehicleOrder(vehicle, 0))
		return true; 
		
	return false;
}

function Scheduler::VehicleIsLoading(vehicle)
{
	if(AIVehicle.GetState(vehicle) != AIVehicle.VS_AT_STATION) 
		return false
	  
	//Does the station supply the cargo we need?
	local cargotype = SLVehicle.GetVehicleCargoType(vehicle);
	
	local vehicleStation = StationManager.StationForVehicle(vehicle)
	
	return SLStation.IsCargoSupplied(vehicleStation, cargotype)
}

function Scheduler::VehicleHasCargoToDeliver(vehicle, cargo)
{
	if(AIVehicle.GetState(vehicle) != AIVehicle.VS_AT_STATION && AIVehicle.GetCargoLoad(vehicle, cargo) > 0)
		return true
	
	//AILog.Info("Vehicle " + vehicle.tostring() + " loading = " + Scheduler.VehicleIsLoading(vehicle).tostring())
	
	if(Scheduler.VehicleIsLoading(vehicle))
	{
		//Are we loading cargo at this station? If so find a destination
		return true
	}
	
	return false
}


function Scheduler::NeedsOrderScrub(vehicle)
{
	/* Returns true if old orders from stations already visited need to be removed from the vehicle */
	
	if(AIVehicle.GetState(vehicle) != AIVehicle.VS_RUNNING) {
		return false; 
	}
	
	if(AIOrder.GetOrderCount(vehicle) > Scheduler.OrderHistoryLength){
		return true;
	}
		
	return false; 
}

function Scheduler::VehicleIsUserManaged(vehicle)
{
	return AIGroup.GetName(AIVehicle.GetGroupID(vehicle)) != null
}

/* Check a vehicles orders to make sure they are valid */
function Scheduler::CheckOrders(vehicle)
{
	
	if(Scheduler.VehicleIsUserManaged(vehicle)) {
		return; 
	}
	
	if(Scheduler.NeedsOrderScrub(vehicle))
	{
		Scheduler.ScrubOrders(vehicle, Scheduler.OrderHistoryLength)
	}
	
	//AILog.Info("CheckOrders vehicle #" + vehicle.tostring())
	//local cargotype = SLVehicle.GetVehicleCargoType(vehicle) 
	
	//local loadsize = AIVehicle.GetCargoLoad(vehicle, cargotype);
	//AILog.Info(loadsize.tostring())
	
	/* Update routes of vehicles at stations or vehicles without orders*/
	if(Scheduler.NeedsRouteUpdate(vehicle))
	{
		//Figure out if we have a pickup or a delivery to make.  
		//Passengers are always treated as pickups.
		local cargotype = SLVehicle.GetVehicleCargoType(vehicle);
		
		if(Scheduler.CargoProducedAndAcceptedAtSameStation(cargotype))
		{
			//AILog.Info("Vehicle " + vehicle.tostring() + " cargo is symettric")
			//If vehicle cargo is both produced and accepted by the same stations we use the pickup routing because the delivery is also a pickup
			Scheduler.RouteToNextPickup(vehicle);
		}
		else
		{
			//AILog.Info("Vehicle " + vehicle.tostring() + " cargo is asymettric")
			//AILog.Info("Vehicle " + vehicle.tostring() + " loading = " + Scheduler.VehicleHasCargoToDeliver(vehicle, cargotype))
			//Assymetric cargo production/acceptance 
			if(Scheduler.VehicleHasCargoToDeliver(vehicle, cargotype)) {
				Scheduler.RouteToDelivery(vehicle);
			}
			else
			{
				/*Just because we do not have cargo to deliver does not mean we need to make a pickup*/
				Scheduler.RouteToNextPickup(vehicle);
			}
			
		}
		
		return
	}
	 
	
	//AILog.Info(AIVehicle.GetState(vehicle).tostring())	
}


/* Returns a scalar from 0.0 to 1.0. Lower ratings return a higher scalar */
function Scheduler::GetRatingWeight(station, cargo)
{
	if(AIStation.HasCargoRating(station, cargo)) 
	{
		local weight = 1.0 - (AIStation.GetCargoRating(station, cargo) / 100.0)
		//weight *= weight
		return weight
	}
	else
	{
		return 1.0	
	}
}

 
function Scheduler::GetSupplyWeight(station, vehicle, cargotype)
{
	/* If a station has enough supply to fill our vehicle it is rated a 1.0
	 Excess cargo is not considered.  Otherwise it rated according to the fraction
	 of the vehicle we can fill */
	 //AILog.Info("GetSupplyWeight " + StationManager.StationString(station))
	 
	 local reservedcargo = StationManager.GetReservedCargoCount(station, cargotype)	 
	 local waitingcargo = AIStation.GetCargoWaiting(station, cargotype)
	 local vehiclecapacity = AIVehicle.GetCapacity(vehicle, cargotype)

	 local unreservedcargo = waitingcargo - reservedcargo;
	
	 if(vehiclecapacity < unreservedcargo)
	 	return 1.0;
	 else
	 	return unreservedcargo.tofloat() / vehiclecapacity.tofloat()
}

function StationPickupAttractiveness(station, vehicle, cargotype)
{	
	local ratingweight = Scheduler.GetRatingWeight(station, cargotype) 
	local score = Scheduler.GetSupplyWeight(station, vehicle, cargotype) * ratingweight
	return (score * 100.0).tointeger()
}

/* Given a list of stations, orders the list according to the best station to visit */
function OrderStationsByPickupAttractiveness(stationlist, vehicle)
{	
	local cargotype = SLVehicle.GetVehicleCargoType(vehicle)
	stationlist.Valuate(StationPickupAttractiveness, vehicle, cargotype)
	StationManager.PrintCargoList(stationlist, cargotype);
	return stationlist;
}

function OrderStationsByDeliveryAttractiveness(stationlist, vehicle)
{
	local cargotype = SLVehicle.GetVehicleCargoType(vehicle)
	
	stationlist.Valuate(StationManager.NumVehiclesEnrouteToStation, cargotype)
	
	stationlist.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING) 
	
	foreach(station, _ in stationlist) 
	{
		AILog.Info("  " + StationManager.NumVehiclesEnrouteToStation(station, cargotype).tostring() + " vehicles enroute to " + StationManager.StationString(station))		
	}
	
	return stationlist
}

/* Add orders to a vehicle to pickup cargo at a station*/
function Scheduler::RouteToNextPickup(vehicle)
{
	local cargotype = SLVehicle.GetVehicleCargoType(vehicle);
	
	AILog.Info("RouteToPickup vehicle #" + vehicle.tostring() + " cargo " + AICargo.GetCargoLabel(cargotype)) 
	local stockpilestations = StationManager.StationsWithStockpile(Scheduler.GetVehicleStationType(vehicle), cargotype);
	
	if(stockpilestations.Count() == 0)
	{
	    AILog.Warning("Vehicle #" + vehicle.tostring() + " has nowhere to go!");
	    return	
	}
	else
	{
		/*Send the vehicle to the first station*/ 
		//Scheduler.ClearVehicleOrders(vehicle);
		
		local orderedStations = OrderStationsByPickupAttractiveness(stockpilestations, vehicle);
		
		foreach( station, _ in orderedStations)
		{
			//AILog.Info("Trying station #" + station.tostring())
			//AILog.Info("Current station #" + AIStation.GetStationID(AIVehicle.GetLocation(vehicle)).tostring())
			if(station == AIStation.GetStationID(AIVehicle.GetLocation(vehicle)))
			{
				//AILog.Info("Ignoring current station #" + station.tostring())
				continue; 
			}
			else
			{
				
				Scheduler.DispatchToStation(vehicle, station, AIOrder.OF_FULL_LOAD );
				break; 
			} 
		}
	}	
}

/* Add orders to a vehicle to deliver a cargo at a station */
function Scheduler::RouteToDelivery(vehicle)
{
	local cargotype = SLVehicle.GetVehicleCargoType(vehicle);
	
	AILog.Info("RouteToDelivery vehicle #" + vehicle.tostring() + " cargo " + AICargo.GetCargoLabel(cargotype)) 
	
	local acceptingstations = StationManager.StationsWithDemand(Scheduler.GetVehicleStationType(vehicle),  cargotype)
	
	if(acceptingstations.Count() == 0)
	{
	    AILog.Warning("Vehicle #" + vehicle.tostring() + " has nowhere to go!");
	    return	
	}
	
	//Lots of ways to decide which station to deliver to.  Try to spread the deliveries according to station congestion for now
	local orderedStations = OrderStationsByDeliveryAttractiveness(acceptingstations, vehicle)
	
	foreach( station, _ in orderedStations)
	{
		//AILog.Info("Trying station #" + station.tostring())
		//AILog.Info("Current station #" + AIStation.GetStationID(AIVehicle.GetLocation(vehicle)).tostring())
		if(station == StationManager.StationForVehicle(vehicle))
		{
			//AILog.Info("Ignoring current station #" + station.tostring())
			continue; 
		}
		else
		{
			Scheduler.DispatchToStation(vehicle, station, AIOrder.OF_NONE);
			break; 
		} 
	}
}



function OrderToString(vehicle, ordernum)
{
	if(!AIOrder.IsValidVehicleOrder(vehicle, ordernum))
		return "Invalid order"
		
	local station = AIStation.GetStationID(AIOrder.GetOrderDestination(vehicle, ordernum))	
	return StationManager.StationString(station)	
}

function Scheduler::ScrubOrders(vehicle, MaxOrders)
{
	AILog.Info("Scrubbing orders for vehicle #" + vehicle.tostring());
	while(AIOrder.GetOrderCount(vehicle) > MaxOrders)
	{ 
		AILog.Info("  Removing order " + OrderToString(vehicle, 0));	
		AIOrder.RemoveOrder(vehicle, 0);
	}	
}

function Scheduler::DispatchToStation(vehicle, station, flags)
{
	AILog.Info("Dispatching vehicle #" + vehicle.tostring() + " to " + StationManager.StationString(station));
	
	AIOrder.AppendOrder(vehicle, AIStation.GetLocation(station), flags);
}

function Scheduler::ClearVehicleOrders(vehicle)
{
	AILog.Info("Clearing orders for vehicle #" + vehicle.tostring());
	while(AIOrder.GetOrderCount(vehicle) > 0)
	{ 
		AIOrder.RemoveOrder(vehicle, 0);
	}	
}