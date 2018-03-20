within ClaRa.Basics.Icons;
model MecahnicalEquilibriumIcon
  annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={Bitmap(
          extent={{-100,-100},{100,100}},
          imageSource=
              "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",
          fileName="modelica://ClaRa/Resources/Images/Components/MechanicalEquilibrium.png")}), Diagram(coordinateSystem(preserveAspectRatio=false)));

end MecahnicalEquilibriumIcon;