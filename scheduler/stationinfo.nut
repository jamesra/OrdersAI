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
	
	static function GetRatingWeight(station, cargo);
	
	static function GetSupplyWeight(station, vehicle, cargo);
	
	static function StationsWithStockpile(station_type, cargo); 
	
	static function StationsWithSupply(station_type, cargo);
	
	static function _IsVehicleTravellingToStation(vehicle, station);
	
	static function VehiclesEnrouteToStation(station, cargo);
	
    static function NumVehiclesEnrouteToStation(station, cargotype);
	
	static function GetReservedCargoCount(station, cargotype);
	
	static function GetLoadingReservedCargoCount(station, cargotype);
	
	static function GetEnrouteReservedCargoCount(station, cargotype);
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

function StationInfo::PrintCargoList(stations, cargo)
{
	foreach( station, rating in stations)
	{
		//local cargowaiting = AIStation.GetCargoWaiting(station, cargo); 
		AILog.Info("    " + StationInfo.StationCargoString(station, cargo) + " score " + rating.tostring() + " @ " + StationInfo.ToString(station));
	}
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
		foundstations = AIStationList(station_type)
		foundstations.Valuate(SLStation.IsCargoSupplied, cargo)
		foundstations.KeepValue(1)
	}
	
	foreach(station,_ in StationInfo.StationsWithStockpile(station_type, cargo))
	{
		if(!foundstations.HasItem(station)){
			foundstations.AddItem(station,1);
			AILog.Warning("Station not found with normal methods, but has a stockpile to pickup " + StationInfo.ToString(station))
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
	
	local foundstations 
	/*local foundstations = AIStationList(station_type)
	foundstations.Valuate(StationInfo.IsCargoAccepted, cargo)
	foundstations.KeepValue(1)
	*/
	
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


function StationInfo::IsCargoAccepted(station, cargo)
{
	local AcceptedCargos = AICargoList_StationAccepting(station)
	local IsAccepted = AcceptedCargos.HasItem(cargo)
	
	if(IsAccepted) {
		AILog.Info(StationInfo.ToString(station) + " accepts " + AICargo.GetCargoLabel(cargo))
	}
	else {
		AILog.Info(StationInfo.ToString(station) + " does not accept " + AICargo.GetCargoLabel(cargo))
	}
	
	return IsAccepted
}
 

function  StationInfo::_IsVehicleTravellingToStation(vehicle, station)
{
	/*Return true if the vehicle is actively running towards the station*/
	if(AIVehicle.GetState(vehicle) != AIVehicle.VS_RUNNING)
	{
		return false;
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


function StationInfo::VehiclesEnrouteToStation(station, cargotype)
{
	/* Returns a list of vehicles travelling to the station to service the specified cargo.
	   cargotype: Set to null returns all vehicles.  Setting a specific cargotype returns all vehicles with capacity for that cargo.
	   */
	
	//AILog.Info("List vehicles travelling to " + StationInfo.ToString(station)) 
	local VehiclesToStation = AIVehicleList()
	if(cargotype != null)
	{
		VehiclesToStation.Valuate(AIVehicle.GetCapacity, cargotype)
		VehiclesToStation.KeepAboveValue(1)
	}
	
	VehiclesToStation.Valuate(StationInfo._IsVehicleTravellingToStation, station)	
	VehiclesToStation.KeepValue(1)
	
	//StationInfo.PrintVehiclesToStationString(station, VehiclesToStation)	
	//StationInfo.PrintVehiclesToStationString(station, VehiclesToStation)
	 
	return VehiclesToStation
}

function StationInfo::NumVehiclesEnrouteToStation(station, cargotype)
{
	/* Returns a simple count of the number of vehicles travelling to the station */
	local vehiclelist = StationInfo.VehiclesEnrouteToStation(station, cargotype)
	return vehiclelist.Count()
}


function StationInfo::GetLoadingReservedCargoCount(station, cargotype)
{
	/*Returns the quantity of cargo we expect to be transported away from the station by vehicles already scheduled to visit, or already visiting and loading*/
	local parkedvehicles = SLStation.GetListOfVehiclesAtStation(station)
	
	parkedvehicles.Valuate(AIVehicle.GetState)
	parkedvehicles.KeepValue(AIVehicle.VS_AT_STATION)
	
	if(parkedvehicles.Count() > 0) {
		AILog.Info("Vehicles loading at " + StationInfo.VehiclesToStationString(station, parkedvehicles))
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


function StationInfo::GetEnrouteReservedCargoCount(station, cargotype)
{
	/*Returns the quantity of cargo we expect to be transported away from the station by vehicles already scheduled to visit, or already visiting and loading*/
	local enroutevehicles = StationInfo.VehiclesEnrouteToStation(station, cargotype)
	if(enroutevehicles == null)
		AILog.Warning("Error, enroute vehicles is null")
	
	if(enroutevehicles.Count() > 0) {
		AILog.Info("Vehicles enroute to " + StationInfo.VehiclesToStationString(station, enroutevehicles))
	}  
	
	//TODO: Vehicles currently loading have the full capacity counted against the reserved cargo count.  Fix this.
	enroutevehicles.Valuate(AIVehicle.GetCapacity, cargotype)
	
	local totalReservation = 0
	foreach (v, capacity in enroutevehicles) 
	{
		totalReservation += capacity
	}
	
	return totalReservation
}