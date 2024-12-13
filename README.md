# koopmanQBO

Code for Valva + Gerber 2024,  *The QBO, the annual cycle, and their interactions: Isolating periodic modes with Koopman analysis* ([preprint][https://doi.org/10.48550/arXiv.2407.17422]). Files run with NLSA base code found here: <https://github.com/dg227/NLSA>. Run by changing steps in QBO_run.m to true, after adjusting data files to the correct paths on your computer. 

I'm happy to take questions, etc. Data used in the paper is either ERA5 or $w^*$ from <https://doi.org/10.5281/zenodo.7081436>. 

Overview of method: 

**Delay embed data**
Replace the input data $\mathcal{D}$ with a larger $\hat{\mathcal{D}}$ of size $(N_t - (N_e - 1)) \times (N_d \cdot N_e)$, so that 

$$ \displaystyle \hat{\mathcal{D}}_t = (\mathcal{D}_t, \mathcal{D}_{t - 1}, \dots , \mathcal{D}_{t - (N_e - 1)}). $$

**Construction of nonlinear basis** We construct nonlinear basis functions $\{\varphi_j\}$ from an eigendecomposition of a kernel matrix $D$ constructed from delay embedded data. We define $D_{ij} = k(\mathcal{\hat{D}}_i, \mathcal{\hat{D}}_j)$ where $k$ is a symmetric positive definite kernel function. Then, the basis functions $\varphi_j$ are determined from the following eigendecomposition.
$$ D \varphi_j = \nu_j \varphi_j $$  
This is equivalent to the algorithm nonlinear Laplacian spectral analysis (NLSA). We truncate our basis to have total dimension $N$.

**Approximation of Koopman generator in $\{\varphi_j\}$ basis**
Recall the formulation of the Koopman generator $V$:
$$Vg = \lim_{t \to 0} \frac{K^t g - g}{t}. $$
The application of the approximate operator $\tilde{V}$ acting on a basis function $\varphi_j$ is approximated with a finite difference scheme. Then $\tilde{V}$ (the approximate Koopman generator in the $\varphi_j$) is \textit{symmetrized} to give a unitary operator: $V = (\tilde{V} - \tilde{V}^*) / 2$.

**Regularize operator with diffusion** A small amount of diffusion is added to the Koopman generator $V$ for regularization,
$$ W = V - \alpha D, $$
where $\alpha$ is a small postive parameter.

**Compute eigendecomposition**
The final eigenfunction and eigenvalue pairs $(\omega_j, \zeta_j)$ come from the eigendecomposition of $W$.
$$ W \zeta_j = \omega_j \zeta_j $$

**Project data for eigenmodes**
Project data $\mathcal{D}$ onto the eigenfunctions $\zeta_j$ (using Nyström embedding) to get Koopman mode $M_j$.



**Papers that also use the same computational method include:**
- Lintner, B. R., D. Giannakis, M. Pike, J. Slawinska (2023). Identification of the Madden–Julian Oscillation with data-driven Koopman spectral analysis. *Geophys. Res. Lett.*, 50, e2023GL102743. <doi:/10.1029/2023GL102743> 
   with acommpanying code: https://github.com/dg227/NLSA/tree/a73b4e51d10ecc51f398bbcd07b502a0d1622bd1/pubs/LintnerEtAl23_GRL
- G. Froyland, D. Giannakis, B. Lintner, M. Pike, J. Slawinska (2021). Spectral analysis of climate dynamics with operator-theoretic approaches. *Nat. Commun.* 12, 6570. doi:10.1038/s41467-021-26357-x
   with accompanying code: https://github.com/dg227/NLSA/tree/a73b4e51d10ecc51f398bbcd07b502a0d1622bd1/pubs/FroylandEtAl21_NatComms 