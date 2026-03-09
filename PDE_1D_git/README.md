# 1D Example

This example reproduces the one-dimensional numerical experiment presented in the paper.

## Required Data

No external data are required for this example.

## Steps to reproduce

1. Run the simulation

run:

Main.m

2. Generate figures (Figure 1 in the paper)

run:

plot_results.m

<p align="center">
  <img src="https://github.com/2lineok/Optimal-Control/blob/main/PDE_1D_git/Figure_1.png" width="800">
</p>

## Model Parameters

The parameters defining the PDE model used in the simulation:

- Diffusion coefficient: D = 0.002
- Growth rate: ρ = 0.012
- Regularization parameter: α = 100
- Maximum simulation time: T = 42

## Algorithm Parameters

The parameters controlling the numerical iteration and optimization:

- Convergence tolerance: crit_tol = 1e-9
- Linear Combination Adjoint Method parameter: 0 < beta = 0.5 < 1
