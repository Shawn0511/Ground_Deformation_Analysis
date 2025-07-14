# ——————————————————————————————————————————————
##  Libraries & CmdStan 
# ——————————————————————————————————————————————
library(tidyverse)
library(readr)
library(cmdstanr)   
library(posterior) 
library(bayesplot)
options(mc.cores = parallel::detectCores())


# cmdstanr::install_cmdstan()

###########################
## Load & pre-process data 
###########################
HPWB_settle <- read_csv(here::here("data", "HP_WB_settlement.csv"))

## -- factorise columns you might keep as covariates -------
HPWB_settle <- HPWB_settle %>%
  drop_na(Z_settlement) %>%
  mutate(
    Ground_Type      = factor(Ground_Type),
    Excavate_method  = factor(Excavate_method)
  )

## -- derive optional geometry helpers ---------------------
HPWB_settle <- HPWB_settle %>% 
  mutate(
    Sensor_Cover = Sensor_Depth - (Tunnel_Depth - Diameter/2),
    Rel_Depth    = Sensor_Depth / Tunnel_Depth
  )

## -- pull constants (z0, D, etc.)  ------------------------
z0 <- unique(HPWB_settle$Tunnel_Depth) %>% as.numeric()
D  <- unique(HPWB_settle$Diameter)     %>% as.numeric()
stopifnot(length(z0)==1, length(D)==1)   # one tunnel only


############################################################
## Design matrices (silent if single level) -----------
############################################################
one_hot <- function(f){           # safe one-hot
  if(nlevels(f) <= 1) {
    matrix(0, nrow = 1, ncol = 0)   # 0-col matrix
  } else {
    model.matrix(~ f - 1)
  }
}

Gmat <- one_hot(HPWB_settle$Ground_Type)
Mmat <- one_hot(HPWB_settle$Excavate_method)

G <- ncol(Gmat)
M <- ncol(Mmat)


################################
##  Data list for Stan  
################################
stan_data <- list(
  N   = nrow(HPWB_settle),
  G   = G,
  M   = M,
  x   = HPWB_settle$X_long,
  y   = HPWB_settle$Y_trans,
  z   = HPWB_settle$Sensor_Depth,
  w   = HPWB_settle$Z_settlement,
  z0  = z0,
  D   = D,
  Gmat = if(G) Gmat else matrix(0, nrow = nrow(HPWB_settle), ncol = 0),
  Mmat = if(M) Mmat else matrix(0, nrow = nrow(HPWB_settle), ncol = 0),
  # process covariates — not yet used inside Stan
  Water_table   = unique(HPWB_settle$Water_table),
  Face_press    = unique(HPWB_settle$Ave_face_pre),
  Grout_press   = unique(HPWB_settle$Ave_grout_pre),
  Ovb_press     = unique(HPWB_settle$insitu_ovb_pre)
)

################################################
## Stan model code (baseline fixed-effects) (single tunnel) 
################################################
stan_code <- '
functions{
  real K_depth(real z, real z0, real aK, real bK){
    return aK + bK * (1 - z/z0) / (1 - z/z0);
  }
}
data{
  int<lower=1> N;
  int<lower=0> G;
  int<lower=0> M;
  vector[N] x; vector[N] y; vector[N] z;
  vector[N] w;
  real z0; real D;
  matrix[N, G] Gmat;
  matrix[N, M] Mmat;
  // process covariates kept for future but unused here
  real Water_table;
  real Face_press;
  real Grout_press;
  real Ovb_press;
}
parameters{
  real log_VL;
  real kappa_base;
  vector[G] gamma_k;        // 0-length if G=0
  real log_ix_base;
  vector[G] delta_g;
  vector[M] delta_m;        // 0-length if M=0
  real x0;

  real<lower=0> gamma_c;
  real<lower=0> aK;
  real<lower=0> bK;

  real<lower=0> sigma;
}
transformed parameters{
  real kappa = kappa_base +
               (G ? (row(Gmat,1) * gamma_k) : 0);
  real i_x   = exp( log_ix_base +
                    (G ? (row(Gmat,1)*delta_g) : 0) +
                    (M ? (row(Mmat,1)*delta_m) : 0) );

  real i0    = kappa * z0;
  real Smax0 = gamma_c * exp(log_VL) * square(D) / i0;

  vector[N] mu;
  for(n in 1:N){
    real Kz   = K_depth(z[n], z0, aK, bK);
    real iz   = Kz * (z0 - z[n]);
    real Smaxz= Smax0 * i0 / iz;
    real Fx   = Phi( (x[n]-x0) / i_x );
    mu[n] = -Smaxz * Fx * exp( -0.5 * square(y[n] / iz) );
  }
}
model{
  // priors
  log_VL      ~ normal(-3, 0.5);
  kappa_base  ~ normal(0.5, 0.1);
  gamma_k     ~ normal(0, 0.1);
  log_ix_base ~ normal(log(12), 0.5);
  delta_g     ~ normal(0, 0.5);
  delta_m     ~ normal(0, 0.5);
  x0          ~ normal(0, 4);

  gamma_c ~ normal(0.313, 0.05);
  aK      ~ normal(0.175, 0.05);
  bK      ~ normal(0.325, 0.05);

  sigma   ~ cauchy(0, 1);

  // likelihood
  w ~ normal(mu, sigma);
}
generated quantities{
  vector[N] w_rep = normal_rng(mu, sigma);
}
'


######################
##  Compile & sample 
######################
mod <- cmdstanr::cmdstan_model(write_stan_file(stan_code))

fit <- mod$sample(
  data = stan_data,
  chains = 4, iter_warmup = 1000, iter_sampling = 2000,
  parallel_chains = 4, adapt_delta = 0.9
)

####################
## Diagnostics
####################
print(fit$summary(variables = c("log_VL","kappa","i_x","sigma")), digits = 2)

##  R-hat & ESS overview
bayesplot::mcmc_rhat(rhat(fit$draws()))
bayesplot::mcmc_neff(neff_ratio(fit$draws()))

##  Trace plots for key params
bayesplot::mcmc_trace(fit$draws(variables = c("log_VL","kappa","i_x","sigma")))

##  Posterior predictive check
bayesplot::ppc_dens_overlay(
  y    = stan_data$w,
  yrep = fit$draws("w_rep") |> posterior::as_draws_matrix() |> .[1:100, ]
)

###########################################
##  Posterior predictions on a regular grid
###########################################
# Sample grid: x from −40 to +100 m, y = 0, z = 0 (surface)
new_grid <- tidyr::expand_grid(
  x = seq(-40, 100, by = 1),
  y = 0,
  z = 0,
  case_id = 1  # choose WB case
)

# Build the design parts needed by the Stan function
case_sel <- new_grid$case_id
Kz_grid  <- with(new_grid,
                 0.175 + 0.325 * (1 - z / case_tbl$Tunnel_Depth[case_sel]) /
                   (1 - z / case_tbl$Tunnel_Depth[case_sel]))
iz_grid  <- Kz_grid * (case_tbl$Tunnel_Depth[case_sel] - new_grid$z)

posterior <- fit$draws(c("Smax0", "kappa", "ix", "gamma_c", "aK", "bK", "sigma"))
pred_df  <- posterior::as_draws_df(posterior)

# pick 100 posterior draws for prediction
set.seed(1)
draw_idx <- sample(seq_len(nrow(pred_df)), 100)

pred_long <- map_dfr(draw_idx, function(k){
  with(pred_df[k, ], {
    i0   <- kappa * z0
    mu_x <- -Smax0 * pnorm((new_x - x0)/ i_x)      # at y=0, z=0
    tibble(draw = k, x = new_x,
           HPWB_settle = rnorm(length(new_x), mu_x, sigma))
  })
})

##  95 % band
pred_band <- pred_long %>% 
  group_by(x) %>% 
  summarise(med = median(HPWB_settle),
            lo  = quantile(HPWB_settle, .025),
            hi  = quantile(HPWB_settle, .975))

ggplot(pred_band, aes(x, med)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = "grey80") +
  geom_line(size = 1) +
  labs(y = "Settlement (mm)", x = "Longitudinal offset (m)",
       title = "95 % posterior band – surface, y = 0 m")
