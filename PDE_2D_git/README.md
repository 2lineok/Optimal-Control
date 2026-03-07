# 2D Example with PET Data

This example reproduces the two-dimensional numerical experiment using PET imaging data.

## Required Data

This example requires PET imaging data from the ADNI database.  
Researchers must obtain access through:

https://adni.loni.usc.edu/

## Steps to reproduce

1. Run the simulation

run:

Main.m

2. Generate figures

run:

plot_results.m

## Model Parameters

The parameters defining the PDE model used in the simulation:

- Diffusion coefficient: D = 0.02
- Growth rate: ρ = 0.012
- Regularization parameter: α = 1000000
- Maximum simulation time: T = 42

## Algorithm Parameters

The parameters controlling the numerical iteration and optimization:

- Convergence tolerance: crit_tol = 1e-9
- Relaxation factor: beta = 0.5
