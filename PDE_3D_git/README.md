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
  <img src="https://github.com/2lineok/Optimal-Control/blob/main/PDE_2D_git/plot_sphere.png" width="800">
</p>

Run:

```
plot_sphere.m
```

---

**Figure 6**

<p align="center">
  <img src="https://github.com/2lineok/Optimal-Control/blob/main/PDE_2D_git/plot_sphere_time.png" width="800">
</p>

Run:

```
plot_sphere_with_different_time.m
```

---

**Figure 7 and Figure 8**

<p align="center">
  <img src="https://github.com/2lineok/Optimal-Control/blob/main/PDE_2D_git/Compare.png" width="800">
</p>

Run:

```
plot_result.m
```

## Model Parameters

The parameters defining the PDE model used in the simulation:

- Diffusion coefficient: Computed from inver_problem.m
- Growth rate: Computed from inver_problem.m
- Regularization parameter: α = 500000
- Maximum simulation time: T = 8

## Algorithm Parameters

The parameters controlling the numerical iteration and optimization:

- Convergence tolerance: crit_tol = 1e-9
- Linear Combination Adjoint Method parameter: 0 < beta = 0.5 < 1
