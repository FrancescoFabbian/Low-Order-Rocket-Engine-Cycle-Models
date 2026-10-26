# Reduced-Order Thermodynamic Modelling of Liquid Rocket Engines

**MATLAB models of the SSME (RS-25) staged-combustion cycle and the SE-21D expander-bleed cycle.**

## Project overview

This work was developed as a group assignment for the **Extension of Rocket Engines** course taught by **Prof. Manel Soria** at the **Universitat Politècnica de Catalunya (UPC)** during the **2025–2026 academic year**.

**Course:** Extension of Rocket Engines  
**Institution:** Universitat Politècnica de Catalunya (UPC), ESEIAAT  
**Academic year:** 2025–2026  
**Instructor:** Prof. Manel Soria

The objective was to develop and assess modular thermodynamic models capable of predicting the thermodynamic state of the working fluids throughout the components of liquid rocket engines. The project focuses on the **Space Shuttle Main Engine (SSME/RS-25)** and also includes a model of the **SE-21D** engine.

The models use steady-state, primarily **zero-dimensional (0D) component calculations**, with **quasi-one-dimensional (quasi-1D) nozzle expansion**. They represent pumps, turbines, combustion chambers and preburners, heat exchangers, mixers, valves and nozzles. Component-level predictions and cycle results were compared with reference calculations, including published work from the **German Aerospace Center (DLR)**.

## Repository structure


Low\_order\_rocket\_engines\_cycle\_models/
├── MATLAB Codes/
│   ├── Main/
│   │   ├── MAIN\_SSME.m
│   │   ├── SSME\_Validation.m
│   │   ├── MAIN\_SE\_21\_D.m
│   │   └── SE\_21\_D\_Validation.m
│   └── Functions/
│       └── \[component models and supporting MATLAB functions]
├── Sources/
│   └── \[reference material and engine schematics]
├── Presentation Group 2.pdf
└── README.md


The **`Main`** folder contains the two engine-cycle scripts and their corresponding reference-comparison scripts. These scripts call the component and supporting functions stored in **`Functions`**. The group presentation documents the modelling approach and selected results.

## MATLAB setup and execution

**Requirements:** MATLAB and the publicly available **NFP** and **HGS** libraries:

* [**NFP (within the INIST repository)**](https://github.com/ManelSoria/INIST) — thermophysical properties of real fluids, using NIST-derived data. The GitHub repository is named `INIST` but contains `NFP.m` and `DatabaseNFP/`.
* [**HGS**](https://github.com/ManelSoria/HGS) — thermochemistry, gas-mixture properties and equilibrium calculations for combustion products.

Both libraries are external dependencies and are **not included in this repository**.

1. Open MATLAB and set its current folder to the repository root (`Low\_order\_rocket\_engines\_cycle\_models`).
2. In MATLAB, select **Home → Set Path → Add with Subfolders**, choose the **`MATLAB Codes`** folder, and apply the change. This makes both `Main` and `Functions` accessible.
3. Download [**NFP / INIST**](https://github.com/ManelSoria/INIST) and [**HGS**](https://github.com/ManelSoria/HGS) from the linked GitHub repositories. Add the folders containing `NFP.m` and `HGSeq.m` (and any required data/subfolders) to the MATLAB search path.
4. Open and run one of the scripts in **`MATLAB Codes/Main`**:

|Script|Purpose|
|-|-|
|`MAIN\_SSME.m`|Coupled SSME (RS-25) thermodynamic cycle|
|`SSME\_Validation.m`|Component/reference comparisons for the SSME|
|`MAIN\_SE\_21\_D.m`|Coupled SE-21D thermodynamic cycle|
|`SE\_21\_D\_Validation.m`|Component/reference comparisons for the SE-21D|

Alternatively, from the repository root, the project path can be added from the MATLAB Command Window:

```
addpath(genpath(fullfile(pwd, 'MATLAB Codes')))
% Add NFP and HGS to the MATLAB path separately.
run(fullfile('MATLAB Codes', 'Main', 'MAIN\_SSME.m'))
```

The validation scripts are intended for comparisons with reference component conditions; they should **not** be interpreted as fully independent end-to-end simulations. The NFP and HGS libraries are **not included** in this repository; please obtain them directly from their official GitHub repositories.

## Thermodynamic libraries and verification

The project uses two third-party thermodynamic libraries to which **Prof. Manel Soria** contributed:

* [**NFP / INIST**](https://github.com/ManelSoria/INIST), developed by Manel Soria, Lorenzo Frezza and Caleb Fuster, for real-fluid thermophysical properties, including cryogenic hydrogen and oxygen. The database is sourced from NIST.
* [**HGS**](https://github.com/ManelSoria/HGS), originally developed by Caleb Fuster, Manel Soria and Arnau Miró (with further contributors), for combustion-product thermodynamics and chemical-equilibrium calculations.

The group investigated improvements to selected component formulations, including iterative real-fluid pump calculations, and compared calculated states with DLR reference values. For certain individual quantities, the relative discrepancies were of order **10⁻⁴**; this accuracy does not apply to every component or output. An SSME cycle-level error-propagation assessment reported a **3.33% deviation in nozzle exit temperature** relative to the reference value, not a 3.33% uncertainty in overall engine efficiency.

## Authors and acknowledgements

Developed by **Francesco Fabbian, Gabriele Parisi, David Rodríguez López and Jan Sonnenschein** (Group 2, UPC, 2025–2026).

We thank **Prof. Manel Soria**, instructor of *Extension of Rocket Engines*, for his teaching, course materials and guidance. We also acknowledge the contributors to the [NFP / INIST](https://github.com/ManelSoria/INIST) and [HGS](https://github.com/ManelSoria/HGS) libraries used in our work.

## Selected references

* **Herbertz, A. (2016).** “Component Modeling for Rocket Engine Cycle Analysis.” *Transactions of the Japan Society for Aeronautical and Space Sciences, Aerospace Technology Japan*, 14(ists30), Pa\_119–Pa\_127. German Aerospace Center (DLR).
* **Van Hooser, K. P., and Bradley, D. P.** “Space Shuttle Main Engine — The Relentless Pursuit of Improvement.” NASA Marshall Space Flight Center / Pratt \& Whitney Rocketdyne.
* **Thakur, B., and Pegu, I. J. (2017).** “A Review on Cryogenic Rocket Engine.” *International Research Journal of Engineering and Technology*, 4(8).

The MATLAB code is an **academic course project**, not an independently certified engine-design tool. External libraries, published papers and third-party engine schematics remain the intellectual property of their respective authors or publishers; obtain permission or link to the original sources rather than redistributing protected files without authorisation.

