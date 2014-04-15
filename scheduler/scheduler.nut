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
 
import("util.superlib", "SuperLib", 38);

require("stationinfo.nut")
require("vehicleinfo.nut")
require("industryinfo.nut")

SLHelper <- SuperLib.Helper;
SLVehicle <- SuperLib.Vehicle;
SLStation <- SuperLib.Station;
SLIndustry <- SuperLib.Industry;

//Tile <- SuperLib.Tile


class Scheduler
{
	static OrderHistoryLength = 3
	
	static function VehicleIsUserManaged(vehicle);
	
	static function CheckOrders(vehicle);
	
	static function CargoProducedAtTowns(cargotype);
	
	static function CargoProducedAndAcceptedAtSameStation(cargotype);
	
	static function GetVehicleStationType(vehicle); 
	
	static function RouteToTownPickup(vehicle);
	
	static function RouteToCargoPickup(vehicle);
	
	static function RouteToDelivery(vehicle);
	
	static function DispatchToStation(vehicle, station, flags);
	
	static function ClearVehicleOrders(vehicle);
	
};



function Scheduler::TestFunction()
{
	local passcargo = SLHelper.GetPAXCargo()
	local passindustry = AIIndustryList_CargoProducing(passcargo)
	
	passindustry.Valuate(AIIndustry.HasHeliport)
	passindustry.KeepValue(1)
	
	foreach(industry, _ in passindustry)
	{
		AILog.Info("Industry produces passengers: " + AIIndustry.GetName(industry) + " unvisited = " + IndustryInfo.Unvisited(industry, passcargo))
	}	
}

function Scheduler::SkipToNextOrder(vehicle)
{
	local orderposition = AIOrder.ResolveOrderPosition(vehicle, AIOrder.ORDER_CURRENT)
	local nextorder = orderposition + 1
	if(nextorder >= AIOrder.GetOrderCount(vehicle))
		nextorder = 0
	
	AIOrder.SkipToOrder(vehicle, nextorder)
}

/* Check a vehicles orders to make sure they are valid.  Returns true if the route was updated */
function Scheduler::CheckOrders(vehicle)
{
	//Scheduler.TestFunction()
	
	if(!Scheduler.CanVehicleBeScheduled(vehicle)) {
		return false
	}	
	   
	if(Scheduler.NeedsOrderScrub(vehicle))
	{
		Scheduler.ScrubOrders(vehicle, Scheduler.OrderHistoryLength)
	}
	
	if(Scheduler.NeedsOrderSkip(vehicle))
	{
		/* Easiest to clear everything and let the AI figure out the next move */
		AILog.Warning(VehicleInfo.ToString(vehicle) + " needed to skip an order.  Possibly trying to load at a station without supply")
		Scheduler.ClearVehicleOrders(vehicle)		
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
			Scheduler.RouteToTownPickup(vehicle);
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
				Scheduler.RouteToCargoPickup(vehicle);
			}
			
		}
		
		return true
	}
	
	return false
	/*
	else
	{
		AILog.Info(VehicleInfo.ToString(vehicle) + " does not need routing");	
	}
	*/
	 
	
	//AILog.Info(AIVehicle.GetState(vehicle).tostring())	
}


function Scheduler::NeedsOrderSkip(vehicle)
{
	/*Sometimes an order was valid, but the game situation changes so the vehicle should move on.*/

	if(AIVehicle.GetState(vehicle) == AIVehicle.VS_AT_STATION)
	{
		if(Scheduler.CargoProducedAtTowns(SLVehicle.GetVehicleCargoType(vehicle)))
		{
			return false
		}
		
		/* Perhaps the industry producing the cargo closed.  The train should move on in its order list */
		if(VehicleInfo.WaitingToLoad(vehicle) && !VehicleInfo.CanLoad(vehicle))
			return true
	}	
	
	return false
}


function Scheduler::CanVehicleBeScheduled(vehicle)
{ 
	if(SLVehicle.GetVehicleCargoType(vehicle) == null){
		AILog.Info(Vehicle.ToString(vehicle) + " has no valid cargo type. Skipping")
		return false;
	}
	
	//Don't mess with vehicles in depot.  This allows players the chance to move them into a group and issue orders manually
	if(AIVehicle.GetState(vehicle) == AIVehicle.VS_IN_DEPOT) {
		return false;
	}
	
	if(!AIVehicle.IsValidVehicle(vehicle)) {
		return false;
	}
	
	return true; 
}


function Scheduler::CargoProducedAtTowns(cargotype)
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
	//AILog.Info("***** Check for route update " + VehicleInfo.ToString(vehicle) + "*****");
	
	/*Return true if the vehicle needs to be given new orders*/
	if(VehicleInfo.NoValidOrders(vehicle))
	{
		AILog.Info(VehicleInfo.ToString(vehicle) + " no valid orders");
		return true;
	}
		
	if(VehicleInfo.LastOrderIsCompleted(vehicle))
	{
		AILog.Info(VehicleInfo.ToString(vehicle) + " last order completed");
		return true;
	}
	
	if(AIVehicle.GetState(vehicle) == AIVehicle.VS_RUNNING)
	{
		/*Check if we are empty and not heading to load*/
		if(Scheduler.CargoProducedAtTowns(SLVehicle.GetVehicleCargoType(vehicle)))
		{
			if(!VehicleInfo.CanUnloadAtDestination(vehicle))
				return true			
		}
		else
		{
			if(VehicleInfo.IsEmpty(vehicle) && !VehicleInfo.CanLoadAtDestination(vehicle)){
				AILog.Info(VehicleInfo.ToString(vehicle) + " needs to load cargo");
				return true;
			}
			if(VehicleInfo.HasCargo(vehicle) && !VehicleInfo.CanUnloadAtDestination(vehicle)){
				AILog.Info(VehicleInfo.ToString(vehicle) + " needs to unload cargo");
				return true;
			}
		}	
	}
	
	return false;
}


function Scheduler::VehicleHasCargoToDeliver(vehicle, cargo)
{
	if(AIVehicle.GetState(vehicle) != AIVehicle.VS_AT_STATION && AIVehicle.GetCargoLoad(vehicle, cargo) > 0)
		return true
	
	//AILog.Info("Vehicle " + vehicle.tostring() + " loading = " + VehicleInfo.CanLoad(vehicle).tostring())
	
	if(VehicleInfo.CanLoad(vehicle))
	{
		//Are we loading cargo at this station? If so find a destination
		return true
	}
	
	return false
}


function ServiceRatingToWeight(rating)
{
	return 1.0 - (rating / 100.0)
}

function WeightToServiceRating(weight)
{
	return (1.0 - weight) * 100.0	
}


/* Returns a scalar from 0.0 to 1.0. Lower ratings return a higher scalar */
function Scheduler::GetRatingWeight(station, cargo)
{
	if(AIStation.HasCargoRating(station, cargo)) 
	{
		local weight = ServiceRatingToWeight(AIStation.GetCargoRating(station, cargo))
		local good_enough_weight = ServiceRatingToWeight(OrdersAI.GetSetting("good_enough_rating"))
		//The logic looks reversed because weights are reversed.  
		if (weight < good_enough_weight)
		{
			weight = good_enough_weight
		}
		
		return weight
	}
	else
	{
		return 0.5
	}
}

 
function Scheduler::GetSupplyWeight(station, vehicle, cargotype)
{
	/* If a station has enough supply to fill our vehicle it is rated a 1.0
	 Excess cargo is not considered.  Otherwise it rated according to the fraction
	 of the vehicle we can fill */
	 //AILog.Info("GetSupplyWeight " + StationInfo.ToString(station))
	 
	 local reservedcargo = StationInfo.GetEnrouteReservedCargoCount(station, cargotype) + StationInfo.GetLoadingReservedCargoCount(station, cargotype)
	 local waitingcargo = AIStation.GetCargoWaiting(station, cargotype)
	 local vehiclecapacity = AIVehicle.GetCapacity(vehicle, cargotype)

	 local unreservedcargo = waitingcargo - reservedcargo;
	
	 if(vehiclecapacity < unreservedcargo) {
	 	return 1.0;
	 }
	 else
	 {
	 	if(StationInfo.StationUnvisited(station, cargotype)) {
	 		return 1.0
	 	}
	 	else {
	 		return unreservedcargo.tofloat() / vehiclecapacity.tofloat()
	 	}
	 }
}

function StationPickupAttractiveness(station, vehicle, cargotype)
{	
	local ratingweight = Scheduler.GetRatingWeight(station, cargotype) 
    local supplyweight = Scheduler.GetSupplyWeight(station, vehicle, cargotype)
    local min_ratingweight = ServiceRatingToWeight(OrdersAI.GetSetting("min_rating"))
    local output = "  " + StationInfo.ToString(station) + ": ratingweight=" + ratingweight.tostring() + ", supplyweight=" + supplyweight.tostring()
    AILog.Info(output)
	local score = 0

    //The logic looks reversed because weights are reversed.  Equivalient to WeightToServiceRating(ratingweight) < WeightToServiceRating(min_ratingweight)
    if(ratingweight > min_ratingweight && supplyweight < 1)
    {
        AILog.Info("   Low service rating @ " + StationInfo.ToString(station) + " with " + WeightToServiceRating(ratingweight).tostring() + "%, allowed min." + WeightToServiceRating(min_ratingweight).tostring() + "%, ignoring supply")

        // avoid a rush of vehicles to the station:
        // lower score the more vehicles are scheduled to the station
        local vehicles = StationInfo.NumVehiclesScheduledToStation(station, cargotype) + 1
        supplyweight = 1.5 / vehicles
	}

    score = supplyweight * ratingweight

	return (score * 100.0).tointeger()
}

/* Given a list of stations, orders the list according to the best station to visit */
function OrderStationsByPickupAttractiveness(stationlist, vehicle)
{	
	local cargotype = SLVehicle.GetVehicleCargoType(vehicle)
	stationlist.Valuate(StationPickupAttractiveness, vehicle, cargotype)
	StationInfo.PrintCargoList(stationlist, cargotype);
	return stationlist;
}


function RemoveVehicleCurrentStation(stationlist, vehicle)
{ 
	local vehiclestation = AIStation.GetStationID(AIVehicle.GetLocation(vehicle))
	/*
	if(stationlist.HasItem(vehiclestation))
		AILog.Info("  Has item " + StationInfo.ToString(vehiclestation))	
	else
		AILog.Info(" *** NO ITEM ***" + StationInfo.ToString(vehiclestation))
	*/
	stationlist.RemoveItem(vehiclestation)
	/*
	foreach(station, _ in stationlist) 
	{
		AILog.Info("  *** " + StationInfo.ToString(station))		
	}
	*/
	/*
	if(stationlist.HasItem(vehiclestation))
		AILog.Warning("  Item not removed correctly " + StationInfo.ToString(vehiclestation))
	else
	{
		AILog.Info("  Item correctly removed " + StationInfo.ToString(vehiclestation))
	}
		*/
	return stationlist	
	
}


function OrderStationsByDeliveryAttractiveness(stationlist, vehicle)
{
	local cargotype = SLVehicle.GetVehicleCargoType(vehicle)
	
	stationlist.Valuate(StationInfo.GetEnrouteCargoDeliveryCount, cargotype)
	
	stationlist.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING) 
	
	
	foreach(station, enroutecount in stationlist) 
	{
		AILog.Info("  " + enroutecount.tostring() + " units enroute to " + StationInfo.ToString(station))		
	}
	
	/*
	foreach(industry, stockpile in industrylist)
	{
		AILog.Info("  " + AIIndustry.GetName(industry) + " stockpile waiting to be processed " + stockpile.tostring() )
	}
	*/
	/*
	foreach(station, _ in stationlist) 
	{
		AILog.Info("  " + StationInfo.NumVehiclesEnrouteToStation(station, cargotype).tostring() + " vehicles enroute to " + StationInfo.ToString(station))		
	}
	*/
	
	return stationlist
}


function Scheduler::GetTownPickupOrderFlags(vehicle)
{
	local orderFlags = AIOrder.OF_NON_STOP_INTERMEDIATE 
	
	if(AIVehicle.GetVehicleType(vehicle) == AIVehicle.VT_AIR ||
	   AIVehicle.GetVehicleType(vehicle) == AIVehicle.VT_WATER)
	{
		orderFlags = AIOrder.OF_NONE
	}

    switch(OrdersAI.GetSetting("load_town_cargo"))
    {
    	case 0:
    		return orderFlags
        case 1:
            return orderFlags | AIOrder.OF_FULL_LOAD_ANY;
        case 2:
            return orderFlags | AIOrder.OF_FULL_LOAD;
        default:
        	return orderFlags | AIOrder.OF_FULL_LOAD_ANY;
    }  
}


function Scheduler::GetCargoPickupOrderFlags(vehicle)
{ 
	local orderFlags = AIOrder.OF_NON_STOP_INTERMEDIATE 
	
	if(AIVehicle.GetVehicleType(vehicle) == AIVehicle.VT_AIR ||
	   AIVehicle.GetVehicleType(vehicle) == AIVehicle.VT_WATER)
	{
		orderFlags = AIOrder.OF_NONE
	}

    switch(OrdersAI.GetSetting("load_industry_cargo"))
    {
    	case 0:
    		return orderFlags
        case 1:
            return orderFlags | AIOrder.OF_FULL_LOAD_ANY;
        case 2:
            return orderFlags | AIOrder.OF_FULL_LOAD;
        default:
        	return orderFlags | AIOrder.OF_FULL_LOAD_ANY;
    }  
}


/* I saw strange behaviour from SuperLib and NoAI API's with regards to correctly indicating if a station supplied passengers
   created dedicated function to hold the magic workarounds */
function Scheduler::RouteToTownPickup(vehicle)
{
	local cargotype = SLVehicle.GetVehicleCargoType(vehicle);
	
	AILog.Info("RouteToTownPickup " + VehicleInfo.ToString(vehicle) + " cargo " + AICargo.GetCargoLabel(cargotype))
	local stockpilestations = StationInfo.StationsWithDemand(VehicleInfo.GetVehicleStationType(vehicle),  cargotype)
	
	stockpilestations = RemoveVehicleCurrentStation(stockpilestations, vehicle)
	stockpilestations.Valuate(StationInfo.IsValidStationForVehicle, vehicle)
	stockpilestations.KeepValue(1)
	
	
	
	if(stockpilestations.Count() == 0)
	{
	    AILog.Warning(VehicleInfo.ToString(vehicle) + " has nowhere to go!");
	    return	
	}
	else
	{
		/*Send the vehicle to the first station*/ 
		//Scheduler.ClearVehicleOrders(vehicle);
		
		local orderedStations = OrderStationsByPickupAttractiveness(stockpilestations, vehicle);
		

		Scheduler.DispatchToStation(vehicle, orderedStations.Begin(), Scheduler.GetTownPickupOrderFlags(vehicle));

		/*
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
				
				
				break; 
			} 
		}
		*/
	}	
}

/* Add orders to a vehicle to pickup cargo at a station*/
function Scheduler::RouteToCargoPickup(vehicle)
{
	local cargotype = SLVehicle.GetVehicleCargoType(vehicle);
	
	
	AILog.Info("RouteToCargoPickup " + VehicleInfo.ToString(vehicle) + " cargo " + AICargo.GetCargoLabel(cargotype)) 
	local stockpilestations = StationInfo.StationsWithSupply(VehicleInfo.GetVehicleStationType(vehicle), cargotype);
	
	stockpilestations = RemoveVehicleCurrentStation(stockpilestations, vehicle)
	
	stockpilestations.Valuate(StationInfo.IsValidStationForVehicle, vehicle)
	stockpilestations.KeepValue(1)
	
	
	if(stockpilestations.Count() == 0)
	{
	    AILog.Warning(VehicleInfo.ToString(vehicle) + " has nowhere to go!");
	    return	
	}
	else
	{
		/*Send the vehicle to the first station*/ 
		//Scheduler.ClearVehicleOrders(vehicle);
		
		local orderedStations = OrderStationsByPickupAttractiveness(stockpilestations, vehicle);
		orderedStations = RemoveItemsNotMatchingFirstValue(orderedStations)
		
		local chosenStation = orderedStations.Begin()
		if(orderedStations.Count() > 1)
		{
			AILog.Info("Candidate pickup stations with equal weight")
			//StationInfo.PrintStationList(orderedStations)
			chosenStation = NearestStation(orderedStations, vehicle)
		}
		
		
		Scheduler.DispatchToStation(vehicle, chosenStation, Scheduler.GetCargoPickupOrderFlags(vehicle));
		
		
		/*
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
				
				Scheduler.DispatchToStation(vehicle, station, AIOrder.OF_FULL_LOAD_ANY);
				break; 
			} 
		}
		*/
	}	
}


/* Add orders to a vehicle to deliver a cargo at a station */
function Scheduler::RouteToDelivery(vehicle)
{
	local cargotype = SLVehicle.GetVehicleCargoType(vehicle);
	
	AILog.Info("RouteToDelivery vehicle #" + vehicle.tostring() + " cargo " + AICargo.GetCargoLabel(cargotype)) 
	
	local acceptingstations = StationInfo.StationsWithDemand(VehicleInfo.GetVehicleStationType(vehicle),  cargotype)
	
	acceptingstations = RemoveVehicleCurrentStation(acceptingstations, vehicle)
	
	acceptingstations.Valuate(StationInfo.IsValidStationForVehicle, vehicle)
	acceptingstations.KeepValue(1)
	
	if(acceptingstations.Count() == 0)
	{
	    AILog.Warning("Vehicle #" + vehicle.tostring() + " has nowhere to go!");
	    return	
	}
		
	//Lots of ways to decide which station to deliver to.  Try to spread the deliveries according to station congestion for now
	local orderedStations = OrderStationsByDeliveryAttractiveness(acceptingstations, vehicle)
	orderedStations = RemoveItemsNotMatchingFirstValue(orderedStations)
	/*
	AILog.Info("Winning delivery candidates")
	foreach(station, _ in orderedStations)
	{
		AILog.Info("    " + StationInfo.ToString(station)) 
	}
	*/
	
	local deststation = RandListItem(orderedStations)
	
	
	Scheduler.DispatchToStation(vehicle, deststation, AIOrder.OF_NONE);
	/*
	foreach( station, _ in orderedStations)
	{
		//AILog.Info("Trying station #" + station.tostring())
		//AILog.Info("Current station #" + AIStation.GetStationID(AIVehicle.GetLocation(vehicle)).tostring())
		if(station == StationInfo.StationForVehicle(vehicle))
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
	*/
}


function RemoveItemsNotMatchingFirstValue(list)
{
	list.KeepValue(list.GetValue(list.Begin()))
	return list	
}

function ToItem(item)
{
	return item
}


function NearestStation(stations, vehicle)
{
	/* Returns the station nearest to the vehicle */
	stations.Valuate(AIStation.GetDistanceManhattanToTile, AIVehicle.GetLocation(vehicle))
	
	foreach(station, distance in stations)
	{
		AILog.Info("   " + StationInfo.ToString(station) + " distance " + distance.tostring())
	}
	
	stations.Sort(AIList.SORT_BY_VALUE, true)
	
	return stations.Begin()
}

function RandListItem(list)
{
	/* Return a random item from the list.*/
	 
	if(list.Count() == 0)
		return null 
	//else if(list.Count() > 1)
		//AILog.Info(" !!!! Random choice being made!")
		
	local itemindex = AIBase.RandRange(list.Count())
	list.Valuate(ToItem)
	local chosen = list.GetValue(itemindex)
	
	
	 /* This for loop should be doable with indexing on a random number, 
	   but for some reason I wasn't able to get that working with AILists. 
	  */
	local i = 0
	foreach(item, _ in list)
	{
		if(i == itemindex)
		{
			chosen = item
			break	
		}
		i++
	}
	
	//if(list.Count() > 1)
		//AILog.Info(" I choose " + itemindex.tostring() + " " + chosen.tostring() )
		
	return chosen
	
}


function OrderToString(vehicle, ordernum)
{
	if(!AIOrder.IsValidVehicleOrder(vehicle, ordernum))
		return "Invalid order"
		
	local station = AIStation.GetStationID(AIOrder.GetOrderDestination(vehicle, ordernum))	
	return StationInfo.ToString(station)	
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

function Scheduler::ScrubOrders(vehicle, MaxOrders)
{
	//AILog.Info("Scrubbing orders for " + VehicleInfo.ToString(vehicle));
	while(AIOrder.GetOrderCount(vehicle) > MaxOrders)
	{ 
//		AILog.Info("  Removing order " + OrderToString(vehicle, 0));	
		AIOrder.RemoveOrder(vehicle, 0);
	}	
}

function Scheduler::DispatchToStation(vehicle, station, flags)
{
	AILog.Info("Dispatching " + VehicleInfo.ToString(vehicle) + " to " + StationInfo.ToString(station));
	
	AIOrder.AppendOrder(vehicle, AIStation.GetLocation(station), flags)
	
	if(AIVehicle.GetState(vehicle) == AIVehicle.VS_RUNNING) {
		AIOrder.SkipToOrder(vehicle, AIOrder.GetOrderCount(vehicle)-1);
	}
	
	//Make sure  the order we added is used next
}

function Scheduler::ClearVehicleOrders(vehicle)
{
	AILog.Info("Clearing orders for " + VehicleInfo.ToString(vehicle));
	while(AIOrder.GetOrderCount(vehicle) > 0)
	{ 
		AIOrder.RemoveOrder(vehicle, 0);
	}	
}
