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
 
class StationInfo
{
	static function ToString(station);
	
	static function StationCargoString(station, cargo) ;
	
	static function PrintStationCargoList(stations, cargo);
	
	static function StationUnvisited(station, cargo);
	
	static function IsRatingBelowMinRating(rating);
	
	static function GetRatingWeight(station, cargo);
	
	static function GetSupplyWeight(station, vehicle, cargo);
	
	static function StationsWithStockpile(station_type, cargo); 
	
	static function StationsWithSupply(station_type, cargo);
	
	static function _IsVehicleTravellingToStation(vehicle, station);
	
	static function IsValidStationForVehicle(station, vehicle);
	
	static function CanAircraftUseAirport(station, vehicle);
	
	static function VehiclesEnrouteToStation(station, cargo);
	
    static function NumVehiclesEnrouteToStation(station, cargotype);
    
    static function GetEnrouteReservedCargoCount(station, cargotype);
	    
    static function VehiclesScheduledToStation(station, cargo);
	
    static function NumVehiclesScheduledToStation(station, cargotype);
	
	static function GetScheduledReservedCargoCount(station, cargotype);
	
	static function GetLoadingReservedCargoCount(station, cargotype);
	
	static function AvailableCargo(station, cargotype, ticks_into_future);
};


function StationInfo::ToString(station)
{
	return "station #" + station.tostring() + " " + AIStation.GetName(station)
}
	
	
function StationInfo::StationCargoString(station, cargo) 
{
	local output = AIStation.GetCargoWaiting(station, cargo) + " " + AICargo.GetCargoLabel(cargo) + " waiting";
	
	if(AIStation.HasCargoRating(station, cargo))
	{
		output = output + " service rate " + AIStation.GetCargoRating(station, cargo).tostring() + "%"; 
	}
	
	return output;
}


function StationInfo::PrintStationList(stations)
{
	foreach( station, _ in stations)
	{
		//local cargowaiting = AIStation.GetCargoWaiting(station, cargo); 
		AILog.Info("    " + StationInfo.ToString(station));
	}
}


function StationInfo::PrintCargoList(stations, cargo)
{
	foreach( station, rating in stations)
	{
		//local cargowaiting = AIStation.GetCargoWaiting(station, cargo); 
		AILog.Info("    " + StationInfo.StationCargoString(station, cargo) + " score " + rating.tostring() + " @ " + StationInfo.ToString(station));
	}
}


function StationInfo::StationUnvisited(station, cargo)
{
	if(AIStation.HasCargoRating(station, cargo)){
		return false
	}
	
	/*
	if(StationInfo.NumVehiclesEnrouteToStation(station, cargo) > 0) {
		return false
	}*/
	
	if(StationInfo.NumVehiclesScheduledToStation(station, cargo) > 0) {
		return false
	}
	
	AILog.Info("  " + StationInfo.ToString(station) + " is unvisited for " + AICargo.GetCargoLabel(cargo))

	return true
}


function StationInfo::IsRatingBelowMinRating(rating)
{
	/* Return true if station service rating is below threshold set by user for special consideration */ 
   //The logic looks reversed because weights are reversed.  Equivalient to WeightToServiceRating(ratingweight) < WeightToServiceRating(min_ratingweight) 	
	return rating < Weights.ServiceRatingToWeight(OrdersAI.GetSetting("min_rating"))
}


/* Stations with an existing stockpile of cargo */
function StationInfo::StationsWithStockpile(station_type, cargo)
{
	AILog.Info("StationsWithStockpile of cargo " + AICargo.GetCargoLabel(cargo)); 
	
	local stations = AIStationList(station_type);
	stations.Valuate(AIStation.GetCargoWaiting, cargo);
	stations.KeepAboveValue(0);
	stations.Sort(AIList.SORT_BY_VALUE, false);
	
	//PrintStationCargoList(stations, cargo)
	
	return stations
}


function StationInfo::StationsWithTowns(station_type, cargo)
{
	local stations = AIStationList(station_type)
	stations.Valuate(AIStation.GetNearestTown)
	
	local townstations = AIList()
	
	foreach(station, town in stations)
	{
		if(AIStation.IsWithinTownInfluence(station, town))
		{
			townstations.AddItem(station,1);
			AILog.Info(StationInfo.ToString(station) + " has a town");
		}
	}
	
	return townstations
}


/* Returns list of stations which supply the specified cargo */
function StationInfo::StationsWithSupply(station_type, cargo)
{
	AILog.Info("StationsWithSupply of cargo " + AICargo.GetCargoLabel(cargo)); 
	
	local foundstations = null
	
	
	//Workaround for SLStation.IsCargoSupplied not returning stations that supply passengers/mail in base game
	if(Scheduler.CargoProducedAtTowns(cargo))
	{
		foundstations = StationInfo.StationsWithTowns(station_type, cargo)
	}
	else
	{
		foundstations = IndustryInfo.StationsWithSupply(station_type, cargo)
		/*foundstations = AIStationList(station_type)
		foundstations.Valuate(SLStation.IsCargoSupplied, cargo)
		foundstations.KeepValue(1)*/
	}
	
	/* Check for stations that may have transfer cargo */
	foreach(station,_ in StationInfo.StationsWithStockpile(station_type, cargo))
	{
		if(!foundstations.HasItem(station)){
			foundstations.AddItem(station,1);
			//AILog.Warning("Station not found with normal methods, but has a stockpile to pickup " + StationInfo.ToString(station))
		}
	}
		
	foreach( station, _ in foundstations)
	{		 
		AILog.Info("  Supplied by " + StationInfo.ToString(station)); 
	}
	
	if(foundstations.Count() == 0)
	{
		
		AILog.Info("No stations supply desired cargo " + AICargo.GetCargoLabel(cargo));
	}
	
	return foundstations;
}


/* Returns list of stations which supply the specified cargo */
function StationInfo::StationsWithDemand(station_type, cargo)
{
	AILog.Info("StationsWithDemand for cargo " + AICargo.GetCargoLabel(cargo)); 
	 
	local foundstations = AIStationList(station_type)
	foundstations.Valuate(StationInfo.IsCargoAccepted, cargo)
	foundstations.KeepValue(1)
	
	/*
	local foundstations
	//Workaround for SLStation.IsCargoSupplied not returning stations that supply passengers/mail in base game
	if(Scheduler.CargoProducedAtTowns(cargo))
	{
		foundstations = StationInfo.StationsWithTowns(station_type, cargo)
	}
	else
	{
		foundstations = AIStationList(station_type)
		foundstations.Valuate(SLStation.IsCargoAccepted, cargo)
		foundstations.KeepValue(1)
	}
	*/
	
	foreach( station, _ in foundstations)
	{		
		AILog.Info("  Accepted by " + StationInfo.ToString(station)) 
	}
	
	if(foundstations.Count() == 0)
	{
		AILog.Info("  No stations demand cargo " + AICargo.GetCargoLabel(cargo) + "!");
	}
	
	
	return foundstations;
}


function StationInfo::IsValidStationForVehicle(station, vehicle)
{
	/*Even if a station_type matches there can be subtypes which are required.  For example jumbo jets cannot land on helicopter pads*/
	switch(AIVehicle.GetVehicleType(vehicle))
	{
		case AIVehicle.VT_RAIL:
			return true;
		case AIVehicle.VT_WATER:
			return true;
		case AIVehicle.VT_ROAD:
			return true;
		case AIVehicle.VT_AIR:
			return StationInfo.CanAircraftUseAirport(station, vehicle);
	}
	
	AILog.Warning(VehicleInfo.ToString(vehicle) + " is not a known vehicle type")
	return false
}

function AirportValidForSmallPlane(airporttype)
{
	/*
	AILog.Info("My airport type: " + airporttype.tostring())
	AILog.Info("  AT_HELIPORT: " +  AIAirport.AT_HELIPORT.tostring())
	AILog.Info("  AT_HELISTATION: " + AIAirport.AT_HELISTATION.tostring())
	AILog.Info("  AT_HELIDEPOT: " + AIAirport.AT_HELIDEPOT.tostring())
	*/
	
	if(airporttype == AIAirport.AT_HELIPORT || 
			   airporttype == AIAirport.AT_HELISTATION ||
			   airporttype == AIAirport.AT_HELIDEPOT)	
	{
			   return false
	}
			   
	return true
}

function AirportValidForBigPlane(airporttype)
{
	/*
	AILog.Info("My airport type: " + airporttype.tostring())
	AILog.Info("  AT_SMALL: " +  AIAirport.AT_SMALL.tostring())
	AILog.Info("  AT_LARGE: " + AIAirport.AT_LARGE.tostring()) 
	*/
	
	if(!AirportValidForSmallPlane(airporttype))
		return false
		
	if(airporttype == AIAirport.AT_SMALL ||
	   airporttype == AIAirport.AT_LARGE)
	   return false
			   
	return true
}

function StationInfo::CanAircraftUseAirport(station, vehicle)
{
	local engine = AIVehicle.GetEngineType(vehicle)
	local planetype = AIEngine.GetPlaneType(engine)
	
	local airporttype = AIAirport.GetAirportType(AIStation.GetLocation(station))
	
	if(airporttype == AIAirport.AT_INVALID)
	{
		return false
	}
	
	if(planetype == AIAirport.AT_INVALID)
	{
		return false
	}
	
	/*
	AILog.Info("My Plane type: " + planetype.tostring())
	AILog.Info("Heli: " + AIAirport.PT_HELICOPTER.tostring())
	AILog.Info("Small: " + AIAirport.PT_SMALL_PLANE.tostring())
	AILog.Info("Big: " + AIAirport.PT_BIG_PLANE.tostring())
	*/
	
	local valid = false
	switch(planetype)
	{
		case AIAirport.PT_HELICOPTER:
			valid = true
			break;
		case AIAirport.PT_SMALL_PLANE:
			valid = AirportValidForSmallPlane(airporttype)
			break; 
		case AIAirport.PT_BIG_PLANE:
			valid = AirportValidForBigPlane(airporttype)
			break; 
		default: 
			valid = AirportValidForBigPlane(airporttype)
			AILog.Warning("Unknown plane type: " + planetype.tostring())
			break;
	}
	
	/*if(valid)
		AILog.Info("  " + StationInfo.ToString(station) + " airport type " + airporttype.tostring() + " is valid airport for " + VehicleInfo.ToString(vehicle))	
	*/
	
	return valid
}


function StationInfo::IsCargoAccepted(station, cargo)
{
	local AcceptedCargos = AICargoList_StationAccepting(station)
	local IsAccepted = AcceptedCargos.HasItem(cargo)
	
	/*
	if(IsAccepted) {
		AILog.Info(StationInfo.ToString(station) + " accepts " + AICargo.GetCargoLabel(cargo))
	}
	else {
		AILog.Info(StationInfo.ToString(station) + " does not accept " + AICargo.GetCargoLabel(cargo))
	}
	*/
	
	return IsAccepted
}
 

function  StationInfo::_IsVehicleTravellingToStation(vehicle, station)
{
	/*Return true if the vehicle is actively running towards the station*/
	if(!(AIVehicle.GetState(vehicle) == AIVehicle.VS_RUNNING ||
	   AIVehicle.GetState(vehicle) == AIVehicle.VS_BROKEN))
	{
		return false
	}
	
	local v_dest_station = VehicleInfo.Destination(vehicle)
	
	//AILog.Info("  Vehicle " + vehicle.tostring() + " -> " + v_dest_station)
	
	if(v_dest_station != station)
		return false
	
	//local enroute = 
	//AILog.Info("  " + v_dest_station + " == " + station.tostring() + " -> " + enroute.tostring())
	
	return v_dest_station == station  		
}

function StationInfo::StationForVehicle(vehicle)
{
	if(AIVehicle.GetState(vehicle) != AIVehicle.VS_AT_STATION)
		return null
		
	/*Returns the station a vehicle is at or null if vehicle is not at station*/
	return AIStation.GetStationID(AIVehicle.GetLocation(vehicle))	
}


function StationInfo::VehiclesToStationString(station, vehiclelist)
{	
	local output = "   " + StationInfo.ToString(station) + ": "
	
	if(vehiclelist == null || vehiclelist.Count() == 0)
		return output
		
	foreach(vehicle, _ in vehiclelist)
	{
		output += " #" + vehicle.tostring()
	}
	
	return output
}

function StationInfo::PrintVehiclesToStationString(station, vehiclelist)
{	
	local output = StationInfo.VehiclesToStationString(station, vehiclelist);
	if(output == null) {
		return
	}
		
	if(output == ""){
		return
	}
	
	AILog.Info(output)
}


function _VehiclesOrderedToStationByCargo(station, cargotype)
{
	/*Returns the list of vehicles with the station somewhere in the order set.
	 :param cargo_id cargotype: Reduces list to vehicles with capacity for the specified cargotype.  null returns all vehicles regardless of cargotype.
	*/
	//AILog.Info("List vehicles travelling to " + StationInfo.ToString(station)) 
	local VehiclesToStation = AIVehicleList_Station(station)
	if(cargotype != null)
	{
		VehiclesToStation.Valuate(AIVehicle.GetCapacity, cargotype)
		VehiclesToStation.KeepAboveValue(0)
	}
	
	return VehiclesToStation
}


function StationInfo::VehiclesEnrouteToStation(station, cargotype)
{
	/* Returns a list of vehicles travelling to the station to service the specified cargo.
	   :param cargo_id cargotype: Reduces list to vehicles with capacity for the specified cargotype.  null returns all vehicles regardless of cargotype.
	   */
	
	local enroute_vehicles = _VehiclesOrderedToStationByCargo(station, cargotype)
	
	enroute_vehicles.Valuate(StationInfo._IsVehicleTravellingToStation, station)	
	enroute_vehicles.KeepValue(1)
	
	/*	 
	if(scheduled_vehicles.Count() > 0) {
		AILog.Info("    Vehicles enroute to " + StationInfo.VehiclesToStationString(station, enroute_vehicles))
	}  
	*/
	 
	return enroute_vehicles
}

function StationInfo::NumVehiclesEnrouteToStation(station, cargotype)
{
	/* Returns a simple count of the number of vehicles travelling to the station.
	:param cargo_id cargotype: Reduces list to vehicles with capacity for the specified cargotype.  null returns all vehicles regardless of cargotype.
	 */
	local vehiclelist = StationInfo.VehiclesEnrouteToStation(station, cargotype)
	return vehiclelist.Count()
}

function StationInfo::VehiclesScheduledToStation(station, cargotype)
{
	/* All vehicles that will be visiting the station at any point in the future.
	   If carg*/
	local scheduled_vehicles = _VehiclesOrderedToStationByCargo(station, cargotype)
	
	scheduled_vehicles.Valuate(VehicleInfo.NextStationScheduled)
    scheduled_vehicles.KeepValue(station)
    
    /*
	if(scheduled_vehicles.Count() > 0) {
		AILog.Info("    Vehicles scheduled to " + StationInfo.VehiclesToStationString(station, scheduled_vehicles))
	}  
	*/
    
    return scheduled_vehicles
}


function StationInfo::NumVehiclesScheduledToStation(station, cargotype)
{
	/* Vehicles which will be visiting the station with cargo type */
    local scheduled_vehicles = StationInfo.VehiclesScheduledToStation(station, cargotype)
    return scheduled_vehicles.Count()
}


function StationInfo::GetLoadingReservedCargoCount(station, cargotype)
{
	/*Returns the quantity of cargo we expect to be transported away from the station by vehicles already scheduled to visit, or already visiting and loading*/
	local parkedvehicles = SLStation.GetListOfVehiclesAtStation(station)
	
	parkedvehicles.Valuate(AIVehicle.GetState)
	parkedvehicles.KeepValue(AIVehicle.VS_AT_STATION)
	
	if(parkedvehicles.Count() > 0) {
		AILog.Info("    Vehicles loading at " + StationInfo.VehiclesToStationString(station, parkedvehicles))
	}
	
	//TODO: Vehicles currently loading have the full capacity counted against the reserved cargo count.  Fix this.
	parkedvehicles.Valuate(AIVehicle.GetCapacity, cargotype)
	
	local totalReservation = 0
	foreach (v, capacity in parkedvehicles) 
	{
		if(capacity > 0) { 
			totalReservation += (capacity - AIVehicle.GetCargoLoad(v, cargotype))
		}
	}
	
	return totalReservation
}


function StationInfo::GetEnrouteCargoDeliveryCount(station, cargotype)
{
	/* Amount of cargo loaded on trains travelling to the station*/
	local enroutevehicles = StationInfo.VehiclesEnrouteToStation(station, cargotype)
	if(enroutevehicles == null)
		AILog.Warning("Error, enroute vehicles is null")
		
	//TODO: Vehicles currently loading have the full capacity counted against the reserved cargo count.  Fix this.
	enroutevehicles.Valuate(AIVehicle.GetCargoLoad, cargotype)
	
	local totalReservation = 0
	foreach (v, cargocount in enroutevehicles) 
	{
		totalReservation += cargocount
	}
	
	return totalReservation
}

function StationInfo::GetEnrouteReservedCargoCount(station, cargotype)
{
	/*Returns the quantity of cargo we expect to be transported away from the station by vehicles actively running to the station or already visiting and loading*/
	local enroutevehicles = StationInfo.VehiclesEnrouteToStation(station, cargotype)
	return VehicleInfo.GetTotalCargoReservation(enroutevehicles, cargotype)
}

function StationInfo::GetScheduledReservedCargoCount(station, cargotype)
{
	/*Returns the quantity of cargo we expect to be transported away from the station by vehicles actively running to the station or already visiting and loading*/
	local scheduled_vehicles = StationInfo.VehiclesScheduledToStation(station, cargotype)
	return VehicleInfo.GetTotalCargoReservation(scheduled_vehicles, cargotype)
}

function StationInfo::EstimatedProduction(station, cargotype, ticks)
{
	/*	Returns the estimated increase in cargo stockpile due to industry productoin */
	local industries = StationInfo.GetSupplyIndustries(station, cargotype)
	
	industries.Valuate(IndustryInfo.EstimateProduction, cargotype, ticks)
	
	local production_total = 0
	foreach(ind, production in industries) 
	{
		production_total += production
	}
	
	return production_total
}


/*static*/ function StationInfo::GetSupplyIndustries(station_id, cargo_id)
{
	// Get the acceptance tiles
	local supply_tiles = SLStation.GetSupplyCoverageTiles(station_id);

	// For supply it is enough to cover any tile of the industry independent on
	// which tiles that actually have the supply coded at them.
	supply_tiles.Valuate(AIIndustry.GetIndustryID);
	
	local industries = AIList()

	foreach(_, industry_id in supply_tiles)
	{
		if(AIIndustry.IsValidIndustry(industry_id))
		{
			local ind_type = AIIndustry.GetIndustryType(industry_id);
			if(SLIndustry.IsCargoProduced(industry_id, cargo_id))
			{
				if(!industries.HasItem(industry_id))
					industries.AddItem(industry_id, industry_id)
					
				// (neglecting the fact that if there are more than 2
				// stations near the industry, not all of them will
				// be supplied by cargo) 
			}
		}
	}
	
	// No covered industry found
	return industries
}


function StationInfo::AvailableCargo(station, cargotype, ticks_into_future)
{
	local waitingcargo = AIStation.GetCargoWaiting(station, cargotype)
	local production_estimate = 0 //Commented due to performance issues.  StationInfo.EstimatedProduction(station, cargotype, ticks_into_future)
	
	if(production_estimate > 0)
	{
		AILog.Info("  Production estimate for " + ticks_into_future.tostring() + " ticks of travel: +" + production_estimate.tostring() + " units")
	}
	
	return waitingcargo + production_estimate
}
