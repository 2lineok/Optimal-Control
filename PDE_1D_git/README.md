# 1D Example

This example reproduces the one-dimensional numerical experiment presented in the paper.

## Required Data

No external data are required for this example.

## Steps to reproduce

1. Run the simulation

run:

Main.m

2. Generate figures

run:

plot_results.m

## Model Parameters

The parameters defining the PDE model used in the simulation:

- Diffusion coefficient: D = 0.002
- Growth rate: ρ = 0.012
- Regularization parameter: α = 100

## Algorithm Parameters

The parameters controlling the numerical iteration and optimization:

- Convergence tolerance: crit_tol = 1e-9
- Relaxation factor: beta = 0.5
