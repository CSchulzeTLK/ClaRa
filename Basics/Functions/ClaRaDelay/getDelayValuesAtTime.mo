within ClaRa.Basics.Functions.ClaRaDelay;
function getDelayValuesAtTime
//___________________________________________________________________________//
// Component of the ClaRa library, version: 1.3.1                            //
//                                                                           //
// Licensed by the DYNCAP/DYNSTART research team under Modelica License 2.   //
// Copyright  2013-2018, DYNCAP/DYNSTART research team.                      //
//___________________________________________________________________________//
// DYNCAP and DYNSTART are research projects supported by the German Federal //
// Ministry of Economic Affairs and Energy (FKZ 03ET2009/FKZ 03ET7060).      //
// The research team consists of the following project partners:             //
// Institute of Energy Systems (Hamburg University of Technology),           //
// Institute of Thermo-Fluid Dynamics (Hamburg University of Technology),    //
// TLK-Thermo GmbH (Braunschweig, Germany),                                  //
// XRG Simulation GmbH (Hamburg, Germany).                                   //
//___________________________________________________________________________//

  input ClaRa.Basics.Functions.ClaRaDelay.ExternalTable table;
  input Real simulationTime;
  input Real value;
  input Real getTime;
  output Real result;
  //annotation(derivative=getXRGDelayValuesAtTimes_der);
external"C" result = getXRGDelayValuesAtTime(table, simulationTime, value, getTime)
annotation (__iti_dll="ITI_Delay-V1.dll",Library={"Delay-V1","ModelicaExternalC"});
  // annotation (derivative(
  //     zeroDerivative=simulationTime,
  //     zeroDerivative=getTimes) = getXRGDelayValuesAtTimes_der);

end getDelayValuesAtTime;
