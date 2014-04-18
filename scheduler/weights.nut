

class Weights
{
	static function ServiceRatingToWeight(rating);
	
	static function WeightToServiceRating(rating);
	
	static function GetServiceRating(station, cargo);
	
	static function SupplyToWeight(unreservedcargo, vehiclecapacity);
	
	static function AvailableCargo(station, cargotype, ticks_into_future);
	
	static function SupplyWeightForHealthyStation(station, vehicle, cargotype);
	
	static function SupplyWeightForUnderservedStation(station, vehicle, cargotype);
	
};

function Weights::ServiceRatingToWeight(rating)
{
	return 1.0 - (rating / 100.0)
}

function Weights::WeightToServiceRating(weight)
{
	return (1.0 - weight) * 100.0	
}


/* Returns a scalar from 0.0 to 1.0. Lower ratings return a higher scalar */
function Weights::GetServiceRating(station, cargo)
{
	if(AIStation.HasCargoRating(station, cargo)) 
	{
		local rating = AIStation.GetCargoRating(station, cargo)
		local good_enough_rating = OrdersAI.GetSetting("good_enough_rating")
		//The logic looks reversed because weights are reversed.  
		if (rating > good_enough_rating)
		{
			rating = good_enough_rating
		}
		
		return rating
	}
	else
	{
		/*We do not know, so assume the station is underserved*/
		return OrdersAI.GetSetting("min_rating") - 1
	}
}


function Weights::SupplyToWeight(unreserved_cargo_count, vehiclecapacity)
{ 
	if(vehiclecapacity < unreserved_cargo_count) {
		return 1.0
	}
	else
	{
		return unreserved_cargo_count.tofloat() / vehiclecapacity.tofloat()
	}
}
 
 
function Weights::SupplyWeightForHealthyStation(station, vehicle, cargotype)
{
	/* If a station has enough supply to fill our vehicle it is rated a 1.0
	 Excess cargo is not considered.  Otherwise it rated according to the fraction
	 of the vehicle we can fill */
	 //AILog.Info("GetSupplyWeight " + StationInfo.ToString(station))
	 local travel_time = VehicleInfo.GetIdealTraveltime(vehicle, station)
	 local available_cargo = StationInfo.AvailableCargo(station, cargotype, travel_time)
	 
	 
	 local reservedcargo = StationInfo.GetEnrouteReservedCargoCount(station, cargotype) + StationInfo.GetLoadingReservedCargoCount(station, cargotype)
	 
	 local unreservedcargo = available_cargo - reservedcargo; 
	 
	 return Weights.SupplyToWeight(unreservedcargo,  AIVehicle.GetCapacity(vehicle, cargotype))
} 


function Weights::SupplyWeightForUnderservedStation(station, vehicle, cargotype)
{
	/* If a station has enough supply to fill our vehicle it is rated a 1.0
	 Excess cargo is not considered.  Otherwise it rated according to the fraction
	 of the vehicle we can fill */
	 //AILog.Info("GetSupplyWeight " + StationInfo.ToString(station))
	 local travel_time = VehicleInfo.GetIdealTraveltime(vehicle, station)
	 local available_cargo = StationInfo.AvailableCargo(station, cargotype, travel_time)
	  
	 local reservedcargo = StationInfo.GetScheduledReservedCargoCount(station, cargotype) + StationInfo.GetLoadingReservedCargoCount(station, cargotype)
	 
	 local unreservedcargo = available_cargo - reservedcargo; 
	 
	 return Weights.SupplyToWeight(unreservedcargo,  AIVehicle.GetCapacity(vehicle, cargotype))
} 