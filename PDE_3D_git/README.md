# 3D Surface Example with PET Data

This example reproduces the three-dimensional surface experiment using PET imaging data.

## Required Data

This example requires PET imaging data from the ADNI database.  
Researchers must obtain access through:

https://adni.loni.usc.edu/

## Steps to reproduce

### 1. Estimate model parameters from data

Before running the simulation, the diffusion and growth parameters are estimated from the PET data.

Run:

```
inverse_problem.m
```

This script solves the inverse problem and identifies the parameters **D** and **ρ** that best fit the data.

---

### 2. Run the simulation

After estimating the parameters, run the main simulation:

```
Main.m
```

This script executes the core algorithm and generates the simulation data used for the figures.

---

### 3. Generate figures

After running the simulation, the figures in the paper can be generated using the following scripts.

**Figure 5**

<p align="center">
  <img src="https://github.com/2lineok/Optimal-Control/blob/main/PDE_3D_git/Figures/plot_sphere.png" width="800">
</p>

Run:

```
plot_sphere.m
```

---

**Figure 6**

<p align="center">
  <img src="https://github.com/2lineok/Optimal-Control/blob/main/PDE_3D_git/Figures/plot_sphere_time.png" width="800">
</p>

Run:

```
plot_sphere_with_different_time.m
```

---

**Figure 8 and Figure 9**


<p align="center">
  <img src="https://github.com/2lineok/Optimal-Control/blob/main/PDE_3D_git/Figures/Integral.png" width="800">
</p>

<p align="center">
  <img src="https://github.com/2lineok/Optimal-Control/blob/main/PDE_3D_git/Figures/Compare.png" width="800">
</p>

Run:

```
plot_result.m
```

## Model Parameters

The parameters defining the PDE model used in the simulation:

- Diffusion coefficient **D**: estimated from the PET data using `inverse_problem.m`
- Growth rate **ρ**: estimated from the PET data using `inverse_problem.m`
- Regularization parameter **α = 5 × 10⁵**
- Maximum simulation time **T = 8**

## Algorithm Parameters

The parameters controlling the numerical iteration and optimization:

- Convergence tolerance: **crit_tol = 1e-9**
- Linear Combination Adjoint Method parameter: **β = 0.5 (with 0 < β < 1)**
