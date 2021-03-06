within ClaRa.Basics.ControlVolumes.GasVolumes;
model VolumeGas_L4 "An array of flue gas cells."
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

  extends ClaRa.Basics.Icons.Volume_L4;
  extends ClaRa.Basics.Icons.ComplexityLevel(complexity="L4");
  import SI = ClaRa.Basics.Units;
  import Modelica.Constants.eps;

  outer ClaRa.SimCenter simCenter;

  //## S U M M A R Y   D E F I N I T I O N #######################################################################
  model Outline
    extends ClaRa.Basics.Icons.RecordIcon;

    input Basics.Units.Volume volume_tot "Total volume of system" annotation (Dialog(show));

    parameter Integer N_cv "|Discretisation|Number of finite volumes";

    input ClaRa.Basics.Units.PressureDifference Delta_p "Pressure difference between outlet and inlet" annotation (Dialog);
    input Basics.Units.Mass mass_tot "Total fluid mass in system mass" annotation (Dialog(show));
    input Basics.Units.Enthalpy H_tot "Total system enthalpy"  annotation (Dialog(show));
    input Basics.Units.HeatFlowRate Q_flow_tot "Heat flow through entire pipe wall" annotation (Dialog);

    input Basics.Units.Mass mass[N_cv] "Fluid mass in cells" annotation (Dialog(show));
    input Basics.Units.MassFlowRate m_flow[N_cv + 1] "Mass flow through cell borders" annotation (Dialog(show));
  end Outline;

  inner model Summary
    extends ClaRa.Basics.Icons.RecordIcon;
    Outline outline;
    ClaRa.Basics.Records.FlangeGas inlet;
    ClaRa.Basics.Records.FlangeGas outlet;
  end Summary;

  //## P A R A M E T E R S #######################################################################################
  //____Media Data_____________________________________________________________________________________
public
  inner parameter TILMedia.GasTypes.BaseGas medium=simCenter.flueGasModel "Medium to be used" annotation (choicesAllMatching, Dialog(group="Fundamental Definitions"));

  //____Physical Effects_____________________________________________________________________________________
  inner parameter Boolean frictionAtInlet=false "True if pressure loss between first cell and inlet shall be considered"
                                                                                            annotation (choices(checkBox=true),Dialog(group="Fundamental Definitions"));
  inner parameter Boolean frictionAtOutlet=false "True if pressure loss between last cell and outlet shall be considered"
                                                                                            annotation (choices(checkBox=true),Dialog(group="Fundamental Definitions"));
  replaceable model PressureLoss =
      ClaRa.Basics.ControlVolumes.Fundamentals.PressureLoss.Generic_PL.LinearPressureLoss_L4            constrainedby ClaRa.Basics.ControlVolumes.Fundamentals.PressureLoss.PressureLossBaseGas_L4 "Pressure loss model at the tubes side"
                                                                                            annotation(choicesAllMatching,Dialog(group="Fundamental Definitions"));

  replaceable model HeatTransfer =
      ClaRa.Basics.ControlVolumes.Fundamentals.HeatTransport.Generic_HT.Constant_L4  constrainedby ClaRa.Basics.ControlVolumes.Fundamentals.HeatTransport.HeatTransferBaseGas_L4 "Heat transfer mode at the tubes side"
                                                                                            annotation(choicesAllMatching,Dialog(group="Fundamental Definitions"));

  //____Geometric data_____________________________________________________________________________________

  replaceable model Geometry =
      ClaRa.Basics.ControlVolumes.Fundamentals.Geometry.GenericGeometry_N_cv                          constrainedby ClaRa.Basics.ControlVolumes.Fundamentals.Geometry.GenericGeometry_N_cv "Pipe geometry"
                                                                                            annotation(choicesAllMatching,Dialog(group="Geometry"));

  //____Nominal Values_________________________________________________________________________________
  parameter Basics.Units.Pressure p_nom[geo.N_cv]=1e5*ones(geo.N_cv) "Nominal pressure"
                                                                                       annotation(Dialog(group="Nominal Values"));
  parameter Basics.Units.Temperature T_nom[geo.N_cv]=293.15*ones(geo.N_cv) "Nominal temperature for single tube"
                                                                                                                annotation(Dialog(group="Nominal Values"));
  parameter Basics.Units.MassFraction xi_nom[medium.nc - 1]={0.01,0,0.1,0,0.74,0.13,0,0.02,0} "Nominal gas composition"
                                                                                                                       annotation(Dialog(group="Nominal Values"));

  inner parameter Basics.Units.MassFlowRate m_flow_nom=100 "Nominal mass flow w.r.t. all parallel tubes"
                                                                                                        annotation(Dialog(group="Nominal Values"));

  inner parameter Basics.Units.Pressure Delta_p_nom=1e4 "Nominal pressure loss w.r.t. all parallel tubes"
                                                                                                         annotation(Dialog(group="Nominal Values"));

  final parameter Basics.Units.DensityMassSpecific rho_nom[geo.N_cv]=TILMedia.GasFunctions.density_pTxi(
      medium,
      p_nom,
      T_nom,
      xi_nom) "Nominal density";

  //____Initialisation_____________________________________________________________________________________
  inner parameter Integer initOption=0  "Type of initialisation"   annotation (Dialog(tab="Initialisation"), choices(
      choice=0 "Use guess values",
      choice=1 "Steady states",
      choice=201 "Steady pressure",
      choice=202 "Steady enthalpy",
      choice=202 "Steady temperature",
      choice=208 "Steady pressure and enthalpy"));
  inner parameter Boolean useHomotopy=simCenter.useHomotopy "true, if homotopy method is used during initialisation" annotation(Dialog(tab="Initialisation",group="Model Settings"));

  parameter Basics.Units.Temperature T_start[:]=293.15*ones(geo.N_cv) "Initial temperature for single tube"
                                                                                                           annotation(Dialog(tab="Initialisation"));
  parameter Basics.Units.Pressure p_start[:]=1e5*ones(geo.N_cv) "Initial pressure" annotation(Dialog(tab="Initialisation"));

  parameter Basics.Units.MassFraction xi_start[medium.nc - 1]={0.01,0,0.1,0,0.74,0.13,0,0.02,0} "Initial gas composition" annotation(Dialog(tab="Initialisation"));
protected
  parameter Basics.Units.Pressure p_start_internal[geo.N_cv]=if size(p_start, 1) == 2 then linspace(
      p_start[1],
      p_start[2],
      geo.N_cv) else p_start "Internal p_start array which allows the user to either state p_inlet, p_outlet if p_start has length 2, otherwise the user can specify an individual pressure profile for initialisation";
  parameter Basics.Units.Temperature T_start_internal[geo.N_cv]=if size(T_start, 1) == 2 then linspace(
      T_start[1],
      T_start[2],
      geo.N_cv) else T_start "Internal T_start array which allows the user to either state T_inlet, T_outlet if T_start has length 2, otherwise the user can specify an individual Temperature profile for initialisation";

  parameter Basics.Units.EnthalpyMassSpecific h_start[geo.N_cv]=TILMedia.GasFunctions.specificEnthalpy_pTxi(
      medium,
      p_start_internal,
      T_start_internal,
      xi_start) "Initial specific enthalpy";
  parameter Basics.Units.DensityMassSpecific d_start[geo.N_cv]=TILMedia.GasFunctions.density_pTxi(
      medium,
      p_start_internal,
      T_start_internal,
      xi_start) "Initial density";

  //## V A R I A B L E   P A R T#######################################################################################

  //____Energy / Enthalpy_________________________________________________________________________________________
public
  Basics.Units.EnthalpyMassSpecific h[geo.N_cv](start=h_start, each stateSelect=StateSelect.prefer) "Cell enthalpy";

  Basics.Units.Temperature T[geo.N_cv](start=T_start_internal) "Cell Temperature";
  SI.Temperature T_in[geo.N_cv] "Inlet temperatures of cells";
  SI.Temperature T_out[geo.N_cv] "Outlet temperatures of cells";

  //____Pressure__________________________________________________________________________________________________
protected
  Basics.Units.Pressure p[geo.N_cv](start=p_start_internal) "Cell pressure"; //nominal=p_nom,
  Basics.Units.Pressure Delta_p_fric[geo.N_cv + 1] "Pressure difference due to friction";

  //____Mass and Density__________________________________________________________________________________________
  Basics.Units.Mass mass[geo.N_cv] "Mass of fluid in cells";
  Basics.Units.Mass mass_FM[geo.N_cv + 1]=cat(
      1,
      {mass[1]/2},
      {(mass[i] + mass[i - 1])/2 for i in 2:geo.N_cv},
      {mass[geo.N_cv]/2}) "Mass of fluid in flow cells";

  Real drhodt[geo.N_cv] "Density derivative"; //(unit="kg/(m3s)")

  Modelica.SIunits.MassFraction xi[geo.N_cv, medium.nc - 1];
  Real Xi_flow[geo.N_cv + 1, medium.nc - 1];

  //____Flows and Velocities______________________________________________________________________________________
  Basics.Units.Power H_flow[geo.N_cv + 1] "Enthalpy flow rate at cell borders";
  Basics.Units.MassFlowRate m_flow[geo.N_cv + 1](nominal=ones(geo.N_cv + 1)*m_flow_nom, start=ones(geo.N_cv + 1)*m_flow_nom);

  Basics.Units.Velocity w[geo.N_cv] "flow velocities within cells of energy model == flow velocities across cell borders of flow model ";
  Basics.Units.Velocity w_inlet "flow velocity at inlet";
  Basics.Units.Velocity w_outlet "flow velocity at outlet";
  Basics.Units.Temperature  T_inlet "Inlet temperature of component";
  Basics.Units.Temperature  T_outlet "Outlet temperature of component";
  Modelica.SIunits.MassFraction xi_inlet[medium.nc - 1] "Inlet gas composition of component";
  Modelica.SIunits.MassFraction xi_outlet[medium.nc - 1] "Outlet gas composition of component";

  //____Connectors________________________________________________________________________________________________
public
  ClaRa.Basics.Interfaces.GasPortIn inlet(Medium=medium) "Inlet port" annotation (Placement(transformation(extent={{-150,-10},{-130,10}}), iconTransformation(extent={{-150,-10},{-130,10}})));
  ClaRa.Basics.Interfaces.GasPortOut outlet(Medium=medium) "Outlet port" annotation (Placement(transformation(extent={{130,-10},{150,10}}), iconTransformation(extent={{130,-10},{150,10}})));

  parameter Boolean showData=false "|Summary and Visualisation||True, if a data port containing p,T,h,s,m_flow shall be shown, else false";

  ClaRa.Basics.Interfaces.HeatPort_a heat[geo.N_cv] annotation (Placement(transformation(extent={{-10,34},{10,54}}), iconTransformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={0,40})));
  //___Instantiation of Replaceable Models___________________________________________________________________________

protected
  inner TILMedia.Gas_ph fluid[geo.N_cv](
    p=p,
    h=h,
    xi=xi,
    each gasType=medium,
    each computeTransportProperties=true) annotation (Placement(transformation(extent={{-10,-42},{10,-22}}, rotation=0)));
public
  PressureLoss pressureLoss "Pressure loss model" annotation (Placement(transformation(extent={{-10,0},{10,20}})));
  HeatTransfer heatTransfer(A_heat=geo.A_heat_CF[:, 1])   "heat transfer model" annotation (Placement(transformation(extent={{-64,0},{-44,20}})));
public
  inner TILMedia.Gas_pT fluidInlet(
    p=inlet.p,
    T=T_inlet,
    xi=xi_inlet,
    gasType=medium) "Gas object at inlet port" annotation (Placement(transformation(extent={{-130,-30},{-110,-10}}, rotation=0)));

  inner TILMedia.Gas_pT fluidOutlet(
    gasType=medium,
    T=T_outlet,
    p=outlet.p,
    xi=xi_outlet) "Gas object at outlet port" annotation (Placement(transformation(extent={{110,-30},{130,-10}}, rotation=0)));

  inner Summary summary(
    outline(N_cv=geo.N_cv,
      volume_tot=sum(geo.volume),
      Delta_p= inlet.p - outlet.p,
      mass_tot=sum(mass),
      H_tot=sum(h .* mass),
      Q_flow_tot=sum(heat.Q_flow),
      mass=mass,
      m_flow=m_flow),
    inlet(mediumModel=medium,
      m_flow=inlet.m_flow,
      T=fluidInlet.T,
      p=inlet.p,
      h=fluidInlet.h,
      xi=fluidInlet.xi,
      H_flow=inlet.m_flow*fluidInlet.h),
    outlet(mediumModel=medium,
      m_flow=-outlet.m_flow,
      T=fluidOutlet.T,
      p=outlet.p,
      h=fluidOutlet.h,
      xi=fluidOutlet.xi,
      H_flow=-outlet.m_flow*fluidOutlet.h)) annotation (Placement(transformation(extent={{-60,-54},{-40,-34}})));

protected
  inner Basics.Records.IComGas_L3 iCom(
    mediumModel=medium,
    xi=xi,
    N_cv=geo.N_cv,
    volume=geo.volume,
    p_in={inlet.p},
    T_in={fluidInlet.T},
    m_flow_in={inlet.m_flow},
    h_in={fluidInlet.h},
    xi_in={fluidInlet.xi},
    xi_out={fluidOutlet.xi},
    p_out={outlet.p},
    T_out={fluidOutlet.T},
    m_flow_out={outlet.m_flow},
    h_out={fluidOutlet.h},
    p_nom=p_nom[1],
    Delta_p_nom=Delta_p_nom,
    m_flow_nom=m_flow_nom,
    h_nom=TILMedia.GasFunctions.specificEnthalpy_pTxi(
        medium,
        p_nom[1],
        T_nom[1],
        xi_start),
    xi_nom=xi_nom,
    T=fluid.T,
    p=p,
    h=h,
    fluidPointer_in={fluidInlet.gasPointer},
    fluidPointer_out={fluidOutlet.gasPointer},
    fluidPointer=fluid.gasPointer,
    final N_inlet=1,
    final N_outlet=1) annotation (Placement(transformation(extent={{-80,-54},{-60,-34}})));

  inner Geometry geo annotation (Placement(transformation(extent={{44,0},{64,20}})));

  //### E Q U A T I O N P A R T #######################################################################################
  //-------------------------------------------
  //initialisation
initial equation
  // m_flow[1:geo.N_cv+1]=inlet.m_flow*ones(geo.N_cv+1);
  if initOption == 1 then  //steady state in pressure and enthalpy
    der(h) = zeros(geo.N_cv);
    der(outlet.p) = 0;
    for i in 1:geo.N_cv loop
     der(xi[i,:])= zeros(medium.nc-1);
    end for;
  elseif initOption == 201 then  //steady pressure
    der(p) = zeros(geo.N_cv);
  elseif initOption == 202 then  //steady enthalpy
    der(h) = zeros(geo.N_cv);
  elseif initOption == 203 then //steady temperature
    T = T_start;
  elseif initOption == 208 then  //steady state in pressure and enthalpy
    der(h) = zeros(geo.N_cv);
    der(outlet.p) = 0;
  elseif initOption == 0 then //no init
    // do nothing
  else
    assert(initOption == 0,"Invalid init option");
  end if;

  for i in 1:geo.N_cv loop
    //xi[i,:]=xi_start[1:end-1]/sum(xi_start);
    xi[i, :] = xi_start[1:end];
  end for;

equation
  T_inlet = noEvent(actualStream(inlet.T_outflow));
  T_outlet = noEvent(actualStream(outlet.T_outflow));
  xi_inlet = noEvent(actualStream(inlet.xi_outflow));
  xi_outlet = noEvent(actualStream(outlet.xi_outflow));

  //-------------------------------------------
  //flow velocities at inlet and outlet
  w_inlet = inlet.m_flow/(geo.A_cross_FM[1]*fluidInlet.d);
  w_outlet = -outlet.m_flow/(geo.A_cross_FM[geo.N_cv + 1]*fluidOutlet.d);

  //flow velocities in cells
  for i in 1:geo.N_cv loop
    w[i] = (m_flow[i] + m_flow[i + 1])/(2*fluid[i].d*geo.A_cross[i]);
  end for;

  //-------------------------------------------
  //data exchange with friction model
  m_flow[1] = inlet.m_flow;
  m_flow = pressureLoss.m_flow;
  m_flow[geo.N_cv + 1] = -outlet.m_flow;

  //-------------------------------------------
  //data exchange with heat transfer model
  heatTransfer.m_flow = m_flow;

  //-------------------------------------------
  //pressure drop due to friction
  for i in 2:geo.N_cv loop
    //pressure due to friction
    Delta_p_fric[i] = pressureLoss.Delta_p[i];
  end for;

  Delta_p_fric[geo.N_cv + 1] = pressureLoss.Delta_p[geo.N_cv + 1];
  Delta_p_fric[1] = pressureLoss.Delta_p[1];

  //-------------------------------------------
  //Enthalpy flows
  for i in 2:geo.N_cv loop
    H_flow[i] = if useHomotopy then homotopy(semiLinear(
      m_flow[i],
      h[i - 1],
      h[i]), h[i - 1]*m_flow_nom) else semiLinear(
      m_flow[i],
      h[i - 1],
      h[i]);
  end for;
  H_flow[1] = if useHomotopy then homotopy(semiLinear(
    m_flow[1],
    fluidInlet.h,
    h[1]), fluidInlet.h*m_flow_nom) else semiLinear(
    m_flow[1],
    fluidInlet.h,
    h[1]);
  H_flow[geo.N_cv + 1] = if useHomotopy then homotopy(semiLinear(
    m_flow[geo.N_cv + 1],
    h[geo.N_cv],
    fluidOutlet.h), h[geo.N_cv]*m_flow_nom) else semiLinear(
    m_flow[geo.N_cv + 1],
    h[geo.N_cv],
    fluidOutlet.h);
  for i in 2:geo.N_cv - 1 loop
    T_in[i] = if m_flow[i] > 0 then T[i - 1] else T[i];
    T_out[i] = if m_flow[i + 1] > 0 then T[i] else T[i + 1];
  end for;
  T_in[1] = if m_flow[1] > 0 then inStream(inlet.T_outflow) else T[1];
  T_out[1] = if m_flow[2] > 0 then T[1] else T[2];
  T_in[geo.N_cv] = if m_flow[geo.N_cv] > 0 then T[geo.N_cv - 1] else T[geo.N_cv];
  T_out[geo.N_cv] = if m_flow[geo.N_cv + 1] > 0 then T[geo.N_cv] else inStream(outlet.T_outflow);

//   for i in 2:geo.N_cv loop
//     Xi_flow[i, :] = if useHomotopy then homotopy(semiLinear(
//       m_flow[i],
//       (xi[i - 1, :] - xi[i, :]),
//       (xi[i, :] - xi[i, :])), (xi[i - 1, :] - xi[i, :])*m_flow_nom) else semiLinear(
//       m_flow[i],
//       (xi[i - 1, :] - xi[i, :]),
//       (xi[i, :] - xi[i, :]));
//   end for;
//   Xi_flow[1, :] = if useHomotopy then homotopy(semiLinear(
//     m_flow[1],
//     (fluidInlet.xi[:] - xi[1, :]),
//     (xi[1, :] - xi[1, :])), (fluidInlet.xi[:] - xi[1, :])*m_flow_nom) else semiLinear(
//     m_flow[1],
//     (fluidInlet.xi[:] - xi[1, :]),
//     (xi[1, :] - xi[1, :]));
//   Xi_flow[geo.N_cv + 1, :] = if useHomotopy then homotopy(semiLinear(
//     m_flow[geo.N_cv + 1],
//     (xi[geo.N_cv, :] - xi[geo.N_cv, :]),
//     (fluidOutlet.xi[:] - xi[geo.N_cv, :])), (xi[geo.N_cv, :] - xi[geo.N_cv, :])*m_flow_nom) else semiLinear(
//     m_flow[geo.N_cv + 1],
//     (xi[geo.N_cv, :] - xi[geo.N_cv, :]),
//     (fluidOutlet.xi[:] - xi[geo.N_cv, :]));

   for i in 2:geo.N_cv loop
     Xi_flow[i, :] = if useHomotopy then homotopy(semiLinear(
       m_flow[i],
       (xi[i - 1, :]),
       (xi[i, :])), (xi[i - 1, :])*m_flow_nom) else semiLinear(
       m_flow[i],
       (xi[i - 1, :]),
       (xi[i, :]));
   end for;
   Xi_flow[1, :] = if useHomotopy then homotopy(semiLinear(
     m_flow[1],
     (fluidInlet.xi[:]),
     (xi[1, :])), (fluidInlet.xi[:])*m_flow_nom) else semiLinear(
     m_flow[1],
     (fluidInlet.xi[:]),
     (xi[1, :]));
   Xi_flow[geo.N_cv + 1, :] = if useHomotopy then homotopy(semiLinear(
     m_flow[geo.N_cv + 1],
     (xi[geo.N_cv, :]),
     (fluidOutlet.xi[:])), (xi[geo.N_cv, :])*m_flow_nom) else semiLinear(
     m_flow[geo.N_cv + 1],
     (xi[geo.N_cv, :]),
     (fluidOutlet.xi[:]));

  //-------------------------------------------
  //Fluid mass in cells
  mass = if useHomotopy then homotopy(geo.volume .* fluid.d, geo.volume .* d_start) else geo.volume .* fluid.d;

  //-------------------------------------------
  // definition of the cells' states:
  for i in 1:geo.N_cv loop
    drhodt[i]*geo.volume[i] = m_flow[i] - m_flow[i + 1] "Mass balance";

    der(xi[i, :]) = 1/mass[i]*((Xi_flow[i, :] -  m_flow[i]*xi[i, :]) - (Xi_flow[i + 1, :] - m_flow[i+1]*xi[i, :])) "Component mass balance";
    fluid[i].drhodp_hxi*der(p[i]) = (drhodt[i] - der(h[i])*fluid[i].drhodh_pxi - sum({fluid[i].drhodxi_ph[j]*der(xi[i, j]) for j in 1:medium.nc - 1})) "Calculate pressure from enthalpy and density derivative";
    der(h[i]) = (H_flow[i] - H_flow[i + 1] + heat[i].Q_flow + der(p[i])*geo.volume[i] - h[i]*geo.volume[i]*drhodt[i])/mass[i];

    T[i] = fluid[i].T;
  end for;


  //-------------------------------------------
  // Static momentum balance:
  // notice that for a static momentum balance we need to apply the same balance as homotopy start equation. Otherwise the equations become trivial.
  // For now we leave the homotopy inside for future development
  for i in 2:geo.N_cv loop
    0 = if useHomotopy then homotopy(p[i - 1] - p[i] - Delta_p_fric[i], p[i - 1] - p[i] - Delta_p_fric[i]) else p[i - 1] - p[i] - Delta_p_fric[i];
  end for;

  inlet.T_outflow = T[1];
  outlet.T_outflow = T[geo.N_cv];

  //enable / disable pressure losses due to friction for flows  inlet --> first cell / last cell --> outlet
  if not frictionAtInlet and not frictionAtOutlet then
    //no friction pressure loss inlet->first cell / no friction pressure loss last cell->outlet
    inlet.p = fluid[1].p;
    outlet.p = fluid[geo.N_cv].p;

  elseif frictionAtInlet and not frictionAtOutlet then
    //friction pressure loss inlet->first cell / no friction pressure loss last cell->outlet
    0 = if useHomotopy then homotopy(inlet.p - p[1] - Delta_p_fric[1], inlet.p - p[1] - Delta_p_fric[1]) else inlet.p - p[1] - Delta_p_fric[1];
    outlet.p = fluid[geo.N_cv].p;

  elseif not frictionAtInlet and frictionAtOutlet then
    //"no friction pressure loss inlet->first cell / friction pressure loss last cell->outlet"
    0 = if useHomotopy then homotopy(p[geo.N_cv] - outlet.p - Delta_p_fric[geo.N_cv + 1], p[geo.N_cv] - outlet.p - Delta_p_fric[geo.N_cv + 1]) else p[geo.N_cv] - outlet.p - Delta_p_fric[geo.N_cv + 1];
    inlet.p = fluid[1].p;

  else
    //friction pressure loss inlet->first cell / friction pressure loss last cell->outlet
    0 = if useHomotopy then homotopy(inlet.p - p[1] - Delta_p_fric[1], inlet.p - p[1] - Delta_p_fric[1]) else inlet.p - p[1] - Delta_p_fric[1];
    0 = if useHomotopy then homotopy(p[geo.N_cv] - outlet.p - Delta_p_fric[geo.N_cv + 1], p[geo.N_cv] - outlet.p - Delta_p_fric[geo.N_cv + 1]) else p[geo.N_cv] - outlet.p - Delta_p_fric[geo.N_cv + 1];

  end if;

  //-------------------------------------------
  //xi
  inlet.xi_outflow[:] = xi[1, :];
  outlet.xi_outflow[:] = xi[geo.N_cv, :];

  connect(heatTransfer.heat, heat) annotation (Line(
      points={{-45,19},{-45,44},{0,44}},
      color={167,25,48},
      thickness=0.5));
  annotation (
    Icon(graphics,
         coordinateSystem(preserveAspectRatio=false, extent={{-140,-50},{140,50}})),
    Diagram(graphics,
            coordinateSystem(preserveAspectRatio=false, extent={{-140,-50},{140,50}})),
    Documentation(info="<html>
<p><b>Model description: </b>A non-adiabatic 1D-tube model using a single pipe cell for the formulation</p>
<p><b>Contact:</b> Johannes Brunnemann, XRG Simulation GmbH</p>
<p>
<b>FEATURES</b>
<ul>
<li>This model uses TILMedia</li>
<li>Flow reversal is supported</li>

<li>distributed pressure loss, i.e. pressure loss occurs in first and second half cell, whereas the state is located in the cell center</li>
</ul></p>
<b>TODO</b>
<ul>

</ul>


<h4>Staggered Grid Approach</h4>


<p>

</p>

<h4>State Definitions</h4>
<p>

</p>


</html>"));
end VolumeGas_L4;
