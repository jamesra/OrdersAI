 

class VehicleInfo
{
	static function VehicleString(vehicle);
	
	static function CanLoad(vehicle);
	
	static function GetVehicleStationType(vehicle);
	
	static function GetAircraftType(vehicle);
	
    static function GetYearsLeft(vehicle);

    static function IsYearsLeftReached(vehicle);

	static function NoValidOrders(vehicle);
	
	static function LastOrderIsCompleted(vehicle);
	
	static function IsEmpty(vehicle);
	
    static function IsStoppedAtDepot(vehicle);

	static function HasCargo(vehicle);
	
	static function Destination(vehicle);
	
	static function CanLoadAtDestination(vehicle);
	
	static function CanUnloadAtDestination(vehicle);
};


function VehicleInfo::ToString(vehicle)
{
	return "Vehicle #" + vehicle.tostring() + " " + AIVehicle.GetName(vehicle);	
}

function VehicleInfo::PrintList(vehicles)
{
	foreach(vehicle, _ in vehicles)
	{
		AILog.Info("    Vehicle #" + vehicle.tostring() + " " + AIVehicle.GetName(vehicle))
	}
}



/* Returns the station type for the vehicle */
function VehicleInfo::GetVehicleStationType(vehicle)
{ 
	return SLStation.GetStationTypeOfVehicle(vehicle)
}


function VehicleInfo::GetAircraftType(vehicle)
{
	if(AIVehicle.GetVehicleType(vehicle) != VT_AIR)
		return AIAirport.PT_INVALID
		
	return AIEngine.GetPlaneType(AIVehicle.GetEngineType(vehicle))
}


function VehicleInfo::CanLoad(vehicle)
{
	if(AIVehicle.GetState(vehicle) != AIVehicle.VS_AT_STATION) 
		return false
	  
	//Does the station supply the cargo we need?
	local cargotype = SLVehicle.GetVehicleCargoType(vehicle);
	
	if(cargotype == null)
	{
		return false; 	
	}
	
	local vehicleStation = StationInfo.StationForVehicle(vehicle)
	
	if(vehicleStation == null)
	{
		return false;	
	}
	
	return SLStation.IsCargoSupplied(vehicleStation, cargotype)
}


function VehicleInfo::WaitingToLoad(vehicle)
{
	if(AIVehicle.GetState(vehicle) != AIVehicle.VS_AT_STATION) 
		return false
	  
	//Does the station supply the cargo we need? 
	local OrderFlags = AIOrder.GetOrderFlags(vehicle, AIOrder.ORDER_CURRENT)
	
	return OrderFlags & AIOrder.OF_LOAD_FLAGS
}



function VehicleInfo::GetYearsLeft(vehicle)
{
    // age left returned in days
    local daysleft = AIVehicle.GetAgeLeft(vehicle)
    //AILog.Info(VehicleInfo.ToString(vehicle) + " has " + daysleft.tostring() + " days left")
    return (daysleft / 365)
}

function VehicleInfo::IsYearsLeftReached(vehicle)
{
    local yearsleft = VehicleInfo.GetYearsLeft(vehicle).tointeger()
    if(yearsleft < OrdersAI.GetSetting("vehicle_years_left"))
    {
        return true;
    }
    return false;
}

function VehicleInfo::NoValidOrders(vehicle)
{
	local VehicleOrderCount = AIOrder.GetOrderCount(vehicle)
	if(VehicleOrderCount == 0)
		return true; 

	if(!AIOrder.IsValidVehicleOrder(vehicle, AIOrder.ORDER_CURRENT))
		return true; 
		
	return false; 
}

function VehicleInfo::LastOrderIsCompleted(vehicle)
{
	local VehicleOrderCount = AIOrder.GetOrderCount(vehicle)
	if(AIVehicle.GetState(vehicle) == AIVehicle.VS_AT_STATION && (AIOrder.ResolveOrderPosition(vehicle, AIOrder.ORDER_CURRENT)+1) == VehicleOrderCount)
	{  
		return true; 
	}
	
	return false;
}

function VehicleInfo::IsEmpty(vehicle)
{
	local cargotype = SLVehicle.GetVehicleCargoType(vehicle);
	return AIVehicle.GetCargoLoad(vehicle, cargotype) == 0;
}

function VehicleInfo::IsStoppedAtDepot(vehicle)
{
    if(AIOrder.IsGotoDepotOrder(vehicle, AIOrder.ORDER_CURRENT) ||
        AIVehicle.GetState == AIVehicle.VS_IN_DEPOT)
    {
        return true;
    }
    return false;
}

function VehicleInfo::HasCargo(vehicle)
{
	local cargotype = SLVehicle.GetVehicleCargoType(vehicle);
	return AIVehicle.GetCargoLoad(vehicle, cargotype) > 0;
}

function VehicleInfo::Destination(vehicle)
{
	/*Returns the station specified by the current order*/
	
	local order_index = AIOrder.ResolveOrderPosition(vehicle, AIOrder.ORDER_CURRENT)
	//AILog.Info(VehicleInfo.ToString(vehicle) + " order index #" + order_index.tostring())
	local dest_station = AIStation.GetStationID(AIOrder.GetOrderDestination(vehicle, order_index))
	//AILog.Info(VehicleInfo.ToString(vehicle) + " enroute to " + StationInfo.ToString(dest_station))
	if(dest_station == null)
		throw (AIError.GetLastErrorString())
	return dest_station
}

function VehicleInfo::NextStationScheduled(vehicle)
{
	/*Returns the station the vehicle will arrive at.  Ignore current station if already at a station*/
	if(AIVehicle.GetState(vehicle) == AIVehicle.VS_RUNNING || 
	   AIVehicle.GetState(vehicle) == AIVehicle.VS_BROKEN )
	{
		return VehicleInfo.Destination(vehicle)
	}
	else
	{
		local order_index = AIOrder.ResolveOrderPosition(vehicle, AIOrder.ORDER_CURRENT)
		order_index++
		
		if(AIOrder.GetOrderCount(vehicle) >= order_index)
		{
			return VehicleInfo.Destination(vehicle)
		}
		
		//AILog.Info(VehicleInfo.ToString(vehicle) + " order index #" + order_index.tostring())
		local dest_station = AIStation.GetStationID(AIOrder.GetOrderDestination(vehicle, order_index))
		//AILog.Info(VehicleInfo.ToString(vehicle) + " enroute to " + StationInfo.ToString(dest_station))
		if(dest_station == null)
			throw (AIError.GetLastErrorString())
		return dest_station
	}
}

function VehicleInfo::CanLoadAtDestination(vehicle)
{
	local DestinationStation = VehicleInfo.Destination(vehicle)	
	local cargo = SLVehicle.GetVehicleCargoType(vehicle)
	local CanLoad = SLStation.IsCargoSupplied(DestinationStation, cargo)
	if(!CanLoad && Scheduler.CargoProducedAtTowns(cargo)) {
		CanLoad = StationInfo.IsCargoAccepted(DestinationStation, cargo)
		//CanLoad = AIStation.IsWithinTownInfluence(DestinationStation, AIStation.GetNearestTown(DestinationStation))
	}
	
	//AILog.Info(VehicleInfo.ToString(vehicle) + " can load at destination " + StationInfo.ToString(DestinationStation) + " = " + CanLoad.tostring())
	return CanLoad
}

function VehicleInfo::CanUnloadAtDestination(vehicle)
{
	local cargo = SLVehicle.GetVehicleCargoType(vehicle)
	local DestinationStation = VehicleInfo.Destination(vehicle)		
	local CanUnload = StationInfo.IsCargoAccepted(DestinationStation, cargo)
	
	if(!CanUnload && Scheduler.CargoProducedAtTowns(cargo))
	{
		CanUnload = AIStation.IsWithinTownInfluence(DestinationStation, AIStation.GetNearestTown(DestinationStation))
		if(CanUnload)
		{
			AILog.Warning(VehicleInfo.ToString(vehicle) + " can unload at destination " + StationInfo.ToString(DestinationStation) + " but StationInfo.IsCargoAccepted returned false!!!")			
		}
	}
	
	//AILog.Info(VehicleInfo.ToString(vehicle) + " can unload at destination " + StationInfo.ToString(DestinationStation) + " = " + CanUnload.tostring())
	return CanUnload
}
