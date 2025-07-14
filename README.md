# 	Statistical Modelling of Tunnelling-induced Ground Deformation
This project investigates how bored tunnelling alters ground-surface and sub-surface levels in different ground conditions(London Clay, Sand etc). The repository combines:

* **classical empirical settlement models** (Inverted Gaussian & CDF profiles),
* **Bayesian regression/GLM** to quantify parameter uncertainty,
* **time-series forecasting** for instrument-level trends, and
* **geostatistical kriging** for 2-D settlement mapping.
  
The toolkit is demonstrated on two landmark London projects:

1. **Crossrail Project – Hyde Park Instrument Site**  
2. **Jubilee Line Extension Project – St James’s Park Instrument Site**


---

## Objectives

| # | Target | Output |
|---|--------|--------|
| 1 | Re-implement & critique legacy empirical models (Inverted-Gaussian trough, volume-loss) |
| 2 | Apply **Bayesian non-linear & GLM** models to capture uncertainty and covariate effects |
| 3 | Capture **temporal evolution** of settlement at fixed instruments |
| 4 | Build **2-D displacement maps** with (co-)kriging & regression-kriging |
| 5 | Ship a modular, reproducible codebase for tunnelling-induced ground response case studies | this repo |

---

## Methods

### 1 Empirical Baseline

| Aspect | Model | Key Equation |
|--------|-------|--------------|
| **Transverse profile** | Gaussian trough | $S(y)=S_{\max}\,\exp\!\bigl(-y^{2}/(2i^{2})\bigr)$ |
| **Longitudinal profile** | Gaussian CDF (sigmoid) | $S(x)=S_{\max}\,\Phi\!\bigl((x-x_{0})/w\bigr)$ |
| **Width parameter** | $i = K\,z_{0}$ with $K\approx 0.4 - 0.6$ for London Clay |


### 2 Bayesian Modelling

#### 2.1 Hierarchical Non-Linear Model  

```math
S_{jk}(y) \sim \mathcal N\!\Bigl(
  S_{\max,k}\,\exp\!\bigl[-y^{2}/\bigl(2\,i_{k}^{2}\bigr)\bigr],
  \;\sigma^{2}
\Bigr)
```

| Parameter | Prior (example) | Notes |
|-----------|-----------------|-------|
| $S_{\max,k}$ | $\mathcal N(20\text{ mm},\,5^{2})$ | Tuned per site |
| $i_{k}$       | $\mathcal N(0.5\,z_{0,k},\,0.1^{2}z_{0,k}^{2})$ | Trough width |
| $\sigma$      | $\text{HalfNormal}(5)$ | Residual scatter |

#### 2.2 Bayesian GLM Layer

```math
\log S_{\max} =
  \beta_{0}
  + \beta_{1}\,\log V_{L}
  + \beta_{2}\,\frac{C}{D}
  + \beta_{3}\,\text{GWT}
  + \ldots
```

**Covariate families**

| Group | Example variables |
|-------|-------------------|
| Geometry | Depth $z_{0}$, Cover/Diameter $C/D$, Diameter $D$ |
| Construction | Volume-loss $V_{L}$, face pressure, advance rate |
| Geotechnical | Soil class, $s_{u}$, $E$, permeability $k$ |
| Hydro | Ground-water table (GWT), Δ pore pressure |


### 3 Time-Series Analysis

* **Granularity**: daily / weekly instrument readings (depends on instrument frequency  )  
* **Decomposition**: STL for trend/seasonality  
* **Models**: ARIMA / SARIMA; Bayesian Dynamic Linear Models for interventions  
* **Validation**: rolling-origin CV; MAE, CRPS, Ljung–Box  
* **Output**: 95 % PI forecasts and exceedance alarms

### 4 Spatial Interpolation

1. **Variography** – assess anisotropy along tunnel axis  
2. **Ordinary & Universal Kriging** (`gstat`, `pykrige`)  
3. **Co-Kriging** – add soil stiffness or GWT as secondary variables  
4. **Regression-Kriging** – drift = GLM predictions + kriged residuals  
5. **Cross-validation** – RMSE & standardized errors  
6. **Deliverables** – GeoTIFF rasters + kriging variance maps

---

##  Repository Layout

```text
├── data/
│   ├── hyde_park/
│   └── st_james_park/
├── notebooks/
│   ├── 01_empirical_analysis.ipynb
│   ├── 02_bayesian_transverse.Rmd
│   ├── 03_longitudinal_profile.Rmd
│   ├── 04_kriging_interpolation.Rmd
│   └── 05_time_series_analysis.ipynb
├── scripts/
│   ├── make_variogram.R
│   └── build_bayesian_glm.R
├── stan_models/
│   └── gaussian_trough.stan
├── figures/
├── .gitignore
├── LICENSE
├── Required_Packages.txt
└── README.md
```


---

## Requirements

* **R (v 4.3+)** – `brms`, `gstat`, `tidyverse`, `cmdstanr`  
* **Python (≥3.10)** – `pandas`, `PyMC`, `statsmodels`, `pykrige`, `matplotlib`  
* **CmdStan / Stan >= 2.33** for custom models  
* **QGIS** for spatial overlays

> Create the conda env:
> ```bash
> conda env create -f environment.yml 
> conda activate tunnel-stats
> ```

---

## Reproducing the Analysis

1. Fetch monitoring data into `data/`.  
2. Run `notebooks/01_empirical_analysis.ipynb` to derive priors & baseline errors.  
3. Knit `02_bayesian_transverse.Rmd` (needs `cmdstanr` backend).  
4. Execute `04_kriging_interpolation.Rmd` to build settlement grids.  
5. Launch `05_time_series_analysis.ipynb` for instrument forecasts & alarm logic.

---

## Key References

* Mair, R. J. & Taylor, R. N. 1997. Bored tunnelling in the urban environment: State-of-the-art report and theme lecture. *Proc.14th Int. Conf. Soil Mech. Found. Eng.* Hamburg, Germany, Vol. 4, pp. 2353–2385.  
* Standing, J. R. Imperial College London Geotechnical Processes Lecture 2 (2018) – *Ground-movement prediction & Tunnelling lecture 2*   
* O'Reilly, M.P. and New, B.M. (1982). Settlements above tunnels in the United Kingdom -their magnitude and prediction. *Tunnelling '82*. London. pp.173-181
* Xue, S. (2023). *Transient ground response during and after tunnelling*. PhD thesis, Imperial College London, London, UK.  

---

## License

This project is released under the MIT License. (See 'LICENSE')


---

