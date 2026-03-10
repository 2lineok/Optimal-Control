# 2D Example with PET Data

This example reproduces the two-dimensional numerical experiment using PET imaging data.

## Required Data

This example requires PET imaging data from the ADNI database.  
Researchers must obtain access through:

https://adni.loni.usc.edu/

## Steps to reproduce

### 1. Run the simulation

Run the main simulation script:

```
Main.m
```

This script executes the core algorithm and reproduces **Figure 2** from the paper.

<p align="center">
  <img src="https://github.com/2lineok/Optimal-Control/blob/main/PDE_2D_git/Figures/Mesh.png" width="800">
</p>

---

### 2. Collect simulation data

When running simulations for multiple subjects (or multiple datasets), the results are first saved separately.  
To combine all generated data files into a single dataset, run:

```
save_all_files.m
```

This script aggregates the results from multiple runs into one file for further analysis and plotting.

---

### 3. Generate figures

After the data aggregation step, the figures in the paper can be generated as follows:

**Figure 3**

<p align="center">
  <img src="https://github.com/2lineok/Optimal-Control/blob/main/PDE_2D_git/Figures/Integral.png" width="800">
</p>

```
plot_integral_results.m
```

**Figure 4**
<p align="center">
  <img src="https://github.com/2lineok/Optimal-Control/blob/main/PDE_2D_git/Figures/Compare.png" width="800">
</p>

```
plot_results.m
```

## Model Parameters

The parameters defining the PDE model used in the simulation:

- Diffusion coefficient: **D = 0.02**
- Growth rate: **ρ = 0.012**
- Regularization parameter: **α = 1000000**
- Maximum simulation time: **T = 42**

## Algorithm Parameters

The parameters controlling the numerical iteration and optimization:

- Convergence tolerance: **crit_tol = 1e-9**
- Linear Combination Adjoint Method parameter: **β = 0.5 (with 0 < β < 1)**
