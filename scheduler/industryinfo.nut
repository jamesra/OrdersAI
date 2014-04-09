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
 
 
class IndustryInfo
{
	static function ToString(industry);
	
	static function Unvisited(industry, cargo);
	
	static function PrintIndustryList(industrylist);
	
	static function AcceptingIndustryLocations(cargotype);
	
	static function StationsWithSupply(stationtype, cargotype);
}

function IndustryInfo::ToString(industry)
{
	return AIIndustry.GetName(industry)	
}

function IndustryInfo::Unvisited(industry, cargo)
{
	return (AIIndustry.GetLastMonthProduction(industry, cargo) == 0) && (AIIndustry.GetStockpiledCargo(industry, cargo) == 0)
}

function IndustryInfo::PrintIndustryList(industrylist)
{
	foreach(ind,_ in industrylist)	
	{
		AILog.Info("  " + IndustryInfo.ToString(ind))	
	}
}

function IndustryInfo::AcceptingIndustryLocations(cargotype)
{
	local industrylist = AIIndustryList_CargoAccepting(cargotype)
	industrylist.Valuate(AIIndustry.GetStockpiledCargo,cargotype)
	industrylist.KeepAboveValue(0)
	
	industrylist.Valuate(AIIndustry.GetLocation)	
	return industrylist
}


function IndustryPossiblyWithinStationRadius(station, industrylist)
{
	local slocation  = AIStation.GetLocation(station)
	//TODO: Should probably use *2 and add the max station spread from game configuration here instead of * 5
	local coverageradius = AIStation.GetStationCoverageRadius(station) * 5
	//AILog.Info(StationInfo.ToString(station) + " coverage radius = " + coverageradius.tostring())
	foreach(industry, ilocation in industrylist)
	{
		local distance = AIStation.GetDistanceManhattanToTile(station, ilocation)
		//AILog.Info("Distance " + IndustryInfo.ToString(industry) + " to " + StationInfo.ToString(station) + " = " + distance.tostring())
		if(coverageradius >= distance)
		{
			//AILog.Info("Distance " + IndustryInfo.ToString(industry) + " to " + StationInfo.ToString(station) + " = " + distance.tostring())
			return true
		}
	}
	
	return false
}


function IndustryInfo::StationsWithSupply(stationtype, cargotype)
{
	local producerlist = AIIndustryList_CargoProducing(cargotype) 
    producerlist.Valuate(AIIndustry.GetAmountOfStationsAround)
	producerlist.KeepAboveValue(0)
	
	//AILog.Info("Master list with stations")
	//IndustryInfo.PrintIndustryList(producerlist)
	producerlist.Valuate(AIIndustry.GetLocation)	
	
	local stationlist = AIStationList(stationtype)
	stationlist.Valuate(IndustryPossiblyWithinStationRadius, producerlist)
	stationlist.RemoveValue(0)
	
	stationlist.Valuate(SLStation.IsCargoSupplied, cargotype)
	stationlist.RemoveValue(0)
	
	return stationlist
}


/*
function IndustryInfo::ProducingIndustryLocations(cargotype)
{
	local industrylist = AIIndustryList_CargoAccepting(cargotype)
	industrylist.Valuate(AIIndustry.GetStockpiledCargo,cargotype)
	industrylist.KeepAboveValue(0)
	
	industrylist.Valuate(AIIndustry.GetLocation)	
	return industrylist
}


function IndustryInfo::IndustriesForStation(station, cargotype)
{
	local coverageradius = AIStation.GetStationCoverageRadius(station)
	foreach(station, llocation
	
}


function IndustryInfo::CargoWaitingForProcessing(station, cargotype)
{
	stationlist.Valuate(AIStation.GetLocation)
	
	foreach(industry, ilocation in industrylist)
	{
		foreach(station, slocation in stationlist)
		{
			local coverageradius = AIStation.GetStationCoverageRadius(station)
			local distance = AIMap.DistanceManhattan(slocation, ilocation)
			if(coverageradius >= distance)
			{
				ret	
			}
		}
	}
}
*/