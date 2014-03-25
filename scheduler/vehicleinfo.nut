 

class VehicleInfo
{
	static function VehicleString(vehicle);
	
	static function IsLoading(vehicle);
	
	static function GetVehicleStationType(vehicle);
	
	static function GetAircraftType(vehicle);
	
	static function NoValidOrders(vehicle);
	
	static function LastOrderIsCompleted(vehicle);
	
	static function IsEmpty(vehicle);
	
	static function HasCargo(vehicle);
	
	static function Destination(vehicle);
	
	static function CanLoadAtDestination(vehicle);
	
	static function CanUnloadAtDestination(vehicle);
};


function VehicleInfo::ToString(vehicle)
{
	return "Vehicle #" + vehicle.tostring() + " " + AIVehicle.GetName(vehicle);	
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


function VehicleInfo::IsLoading(vehicle)
{
	if(AIVehicle.GetState(vehicle) != AIVehicle.VS_AT_STATION) 
		return false
	  
	//Does the station supply the cargo we need?
	local cargotype = SLVehicle.GetVehicleCargoType(vehicle);
	
	local vehicleStation = StationInfo.StationForVehicle(vehicle)
	
	return SLStation.IsCargoSupplied(vehicleStation, cargotype)
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

function VehicleInfo::HasCargo(vehicle)
{
	local cargotype = SLVehicle.GetVehicleCargoType(vehicle);
	return AIVehicle.GetCargoLoad(vehicle, cargotype) > 0;
}

function VehicleInfo::Destination(vehicle)
{
	/*Returns the station the vehicle is travelling to*/
	local order_index = AIOrder.ResolveOrderPosition(vehicle, AIOrder.ORDER_CURRENT)
	//AILog.Info(VehicleInfo.ToString(vehicle) + " order index #" + order_index.tostring())
	local dest_station = AIStation.GetStationID(AIOrder.GetOrderDestination(vehicle, order_index))
	//AILog.Info(VehicleInfo.ToString(vehicle) + " enroute to " + StationInfo.ToString(dest_station))
	if(dest_station == null)
		throw (AIError.GetLastErrorString())
	return dest_station
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