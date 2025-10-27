# Optimal Control for Anti-Amyloid Beta Treatment in Alzheimer's Disease

This repository provides MATLAB codes and data instructions for reproducing the results presented in  
**“Optimal Control for Anti-Aβ Treatment in Alzheimer’s Disease using a Reaction-Diffusion Model”** by  
**Sun Lee, Chiu-Yen Kao, Zhiyuan Li, Tingting Dan, Guorong Wu, and Wenrui Hao (2025)**.

---

## 📘 Overview

This project develops a **reaction-diffusion PDE-based optimal control framework** to model and optimize anti-amyloid beta (Aβ) treatment strategies in Alzheimer's disease (AD). The method integrates:

- **Spatially explicit PDE modeling** of amyloid-beta plaque dynamics,  
- **Finite Element Method (FEM)** for numerical solution,  
- **Adjoint-based optimal control algorithms** for treatment optimization, and  
- **Calibration using PET imaging data** from the **Alzheimer’s Disease Neuroimaging Initiative (ADNI)**.

The framework computes optimal dosing schedules that minimize amyloid plaque burden while accounting for potential side effects such as ARIA.

---

## 🧠 Model Summary

### Governing Equation

The amyloid-beta (Aβ) concentration $u(x, t)$ satisfies:

$$
u_t - \nabla \cdot (D(x)\nabla u) = \rho (1 - u)u - C(t)u, 
\quad (x,t) \in \Omega \times (0,T)
$$

with no-flux boundary conditions:

$$
\frac{\partial u}{\partial n} = 0, \quad \text{on } \partial \Omega
$$

and an initial condition derived from PET imaging data:

$$
u(x,0) = u_0(x)
$$

### Objective Function

The optimization seeks to minimize the functional:

$$
J(C) = \int_0^T \left( \int_\Omega u_C(x,t)\,dx + \alpha C^2(t) \right) dt
$$

where:

- $u_C$: solution under control function $C(t)$  
- $\alpha$: penalty coefficient controlling side-effect weight

The optimal control $C^*(t)$ minimizes $J(C)$.

---

## ⚙️ Implementation

### Numerical Methods

- **Spatial Discretization:** Finite Element Method (FEM)  
- **Temporal Scheme:** Implicit Euler or Crank–Nicolson  
- **Optimization:** Adjoint-based iteration using the *Linear Combination Adjoint Method*

### Algorithm 1: Linear Combination Adjoint Method

1. Initialize control $C_0(t)$.  
2. Solve the **state equation** for $u_i$.  
3. Solve the **adjoint equation** for $w_i$.  
4. Compute intermediate control:

   $$
   \tilde{C} = -\frac{1}{2\alpha} \int_\Omega u_i w_i\,dx
   $$

5. Update the control:

   $$
   C_{i+1} = \beta C_i + (1 - \beta)\tilde{C}, \quad \beta \in [0,1)
   $$

6. Repeat until convergence:

   $$
   \|C_{i+1} - C_i\| < \text{TOL}
   $$

This iterative scheme is guaranteed to converge for sufficiently large $\alpha$.

---

## 🧩 File Structure

```
AD_PDE_Optimal_Control/
│
├── data/
│   └── ADNI_PET/                     # PET imaging data (requires ADNI access)
│
├── src/
│   ├── main_solver.m                 # Main FEM solver for state and adjoint PDEs
│   ├── optimal_control.m             # Linear Combination Adjoint Method implementation
│   ├── parameter_estimation.m        # Inverse estimation for D and ρ
│   ├── utils/                        # Helper functions (mesh generation, visualization, etc.)
│
├── examples/
│   ├── 1D_case.m
│   ├── 2D_case_with_PET.m
│   └── 3D_brain_surface.m
│
├── results/
│   ├── control_vs_constant.png
│   ├── cumulative_difference.png
│   └── validation_accuracy.png
│
└── README.md
```

---

## 📊 Data

- **Dataset:** [Alzheimer’s Disease Neuroimaging Initiative (ADNI)](https://adni.loni.usc.edu)  
- **Usage:** Access requires ADNI registration and approval.  
---

## 🚀 Usage

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/AD_PDE_Optimal_Control.git
   cd AD_PDE_Optimal_Control
   ```

2. Add `src/` to MATLAB path:
   ```matlab
   addpath('src')
   ```

3. Run an example:
   ```matlab
   run('examples/2D_case_with_PET.m')
   ```

4. View results in the `results/` folder.

---

## 📈 Results Summary

- The optimal control consistently **outperforms constant dosing**, reducing cumulative amyloid load.  
- The model was validated on **ADNI PET data** across 5 diagnostic groups (CN, SMC, EMCI, LMCI, AD).  
- Estimated parameters $D$ and $\rho$ were biologically plausible and consistent across subjects.  
- The **optimal treatment** achieved a better trade-off between efficacy and safety.

---

## 🧪 Citation

If you use this code or model, please cite:

> Lee, S., Kao, C.-Y., Li, Z., Dan, T., Wu, G., Hao, W. (2025).  
> *Optimal Control for Anti-Aβ Treatment in Alzheimer’s Disease using a Reaction-Diffusion Model.*  
> (Preprint, under review).

---

## 📜 License

This repository is released for academic and non-commercial use only.  
For commercial or redistribution rights, please contact the authors.

---

## 👥 Authors and Contact

**Primary Contact:**  
Sun Lee (Ph.D. Candidate, Penn State University)  
📧 skl5876@psu.edu  

**Collaborators:**  
- Chiu-Yen Kao (Claremont McKenna College)  
- Zhiyuan Li (Ohio State University)  
- Tingting Dan (UNC Chapel Hill)  
- Guorong Wu (UNC Chapel Hill)  
- Wenrui Hao (Penn State University)

