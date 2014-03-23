 

class VehicleInfo
{
	static function VehicleString(vehicle);
	
	static function IsLoading(vehicle);
	
	static function GetVehicleStationType(vehicle);
	
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
	return AIStation.GetStationID(AIOrder.GetOrderDestination(vehicle, AIOrder.ORDER_CURRENT))
}

function VehicleInfo::CanLoadAtDestination(vehicle)
{
	local DestinationStation = VehicleInfo.Destination(vehicle)		
	local CanLoad = SLStation.IsCargoSupplied(DestinationStation, SLVehicle.GetVehicleCargoType(vehicle))
	//AILog.Info(VehicleInfo.ToString(vehicle) + " can load at destination = " + CanLoad.tostring())
	return CanLoad
}

function VehicleInfo::CanUnloadAtDestination(vehicle)
{
	local DestinationStation = VehicleInfo.Destination(vehicle)		
	local CanUnload = SLStation.IsCargoAccepted(DestinationStation, SLVehicle.GetVehicleCargoType(vehicle))
	//AILog.Info(VehicleInfo.ToString(vehicle) + " can load at destination = " + CanLoad.tostring())
	return CanUnload
}