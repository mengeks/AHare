#--------------------------------------------------------
#--- function calculates asymptotic efficiency for Cox, RMST, AH-SW
#---- (v1) --- censoring will be given by exponential (lambda_c)
#---- (v2) --- censoring will be given by exponential (lambda_c) x uniform
#--------------------------------------------------------
ares_v2 = function(P){

 #-- IN --
 # P --- parameters
 #--------

 #--- derived --
 P$p0=(1-P$p1)
 P$Lambda_t = cumsum(P$lambda_t)*P$increment
 P$S_t = exp(-P$Lambda_t)
 P$RMST_t = cumsum(P$S_t)*P$increment
 P$rev_RMST_t = P$RMST_t[P$k] - P$RMST_t
 
 #-- censoring (v2)
 #-- given by distribution function 
 #-- combination of exp and uniform
 #-- lambda_cens, cens_tau_l, cens_tau_u (see Lu's paper 2017)
 wk1 = exp(- P$lambda_cens * P$x)
 wk2 = pmax(P$x, P$cens_tau_l) 
 wk3 = as.numeric(P$x <= P$cens_tau_u)
 wk4 = wk1 * (P$cens_tau_u - wk2)/(P$cens_tau_u - P$cens_tau_l)*wk3

 P$S_c1_t = wk4 ;
 P$S_c0_t = wk4 ;
 
 P$pi0_t = P$S_t * P$S_c0_t
 P$pi1_t = P$S_t * P$S_c1_t
 
 P$w_t = (P$p0 * P$p1 * P$pi1_t * P$pi0_t)/(P$p0 * P$pi0_t + P$p1 * P$pi1_t)
 P$cum_alpha_lamda_t = cumsum(P$alpha_t * P$lambda_t)*P$increment

 #--- RMST  --
 eff_rmst_numer1 = cumsum(P$cum_alpha_lamda_t * P$S_t)*P$increment
 eff_rmst_numer2 = cumsum(P$rev_RMST_t * P$alpha_t * P$lambda_t)*P$increment
 eff_rmst_var    = cumsum(P$rev_RMST_t^2 / P$w_t * P$lambda_t)*P$increment
 tmp=cbind(eff_rmst_numer1,eff_rmst_numer2,eff_rmst_var)
 ae_rmst = cbind(eff_rmst_numer1, eff_rmst_var, eff_rmst_numer1^2/eff_rmst_var)[P$k,]  
 P$weight_k_rmst = P$rev_RMST_t/P$RMST_t[P$k]
 
 #--- Cox  --
 eff_cox_numer = cumsum(P$w_t * P$lambda_t * P$alpha_t ) * P$increment
 eff_cox_var   = cumsum(P$w_t * P$lambda_t)*P$increment
 ae_cox = cbind(eff_cox_numer, eff_cox_var, eff_cox_numer^2/eff_cox_var)[P$k,]  
 P$weight_k_cox = P$S_c0_t * P$S_t
 
 #--- AH  --
 wk1 = - P$cum_alpha_lamda_t[P$k] / (1-P$S_t[P$k]) * P$S_t[P$k]
 wk2 = - cumsum(P$cum_alpha_lamda_t * P$S_t)*P$increment / P$RMST_t[P$k]
 eff_ah_numer = (wk1 + wk2)
 wk3 = (1/(1-P$S_t[P$k]) - P$RMST_t/P$RMST_t[P$k])^2
 eff_ah_var =  cumsum(wk3 / P$w_t * P$lambda_t)*P$increment
 ae_ah = cbind(eff_ah_numer, eff_ah_var, eff_ah_numer^2/eff_ah_var)[P$k,]  
 P$weight_k_ah = P$S_t[P$k] + (1 - P$S_t[P$k]) * P$rev_RMST_t / P$RMST_t[P$k]
 
 #=================
 out=rbind(ae_cox, ae_rmst, ae_ah)
 colnames(out)=c("mean","var","eff")
 rownames(out)=c("Cox","RMST","AHSW")
 #=================
 effs = out[,3]
 ares = matrix(1,3,3)
 for (i in 1:3){
 for (j in 1:3){
 	ares[i,j]=effs[i]/effs[j]
 }}
 rownames(ares)=c("Cox","RMST","AHSW")
 colnames(ares)=c("Cox","RMST","AHSW")
 #=================
 Z=list()
 Z$parm = P
 Z$ae_rmst = ae_rmst
 Z$ae_cox  = ae_cox
 Z$ae_ah   = ae_ah
 Z$aeff   = effs
 Z$out   = out
 Z$ares   = ares
 
 return(Z)  
}
 
#===============
# example
#===============
if(0){
#--list of the parameters ---
P=list()
P$tau=40; 
P$increment=0.01 ; 
P$x=seq(0,P$tau,by=P$increment) #--- time
P$k=length(P$x)
P$p1=0.5
#-- alpha function (for local alternative) 
P$alpha_t  = c(0, P$x[-1]*0.01 )
P$alpha_t  = c(0, rep(0.01,P$k-1) )
#-- hazard function (lambda) for event
P$lambda_t = c(0, rep(0.1,P$k-1) )
P$lambda_t = c(0,P$x[-1]^(-0.174)/30 ) ; 
#-- censoring 
P$lambda_cens = 0.02
P$cens_tau_l = 20
P$cens_tau_u = 60

ft=ares_v2(P)
ft$out
ft$ares

 plot(ft$parm$x, ft$parm$S_t, type="l", col="red", ylim=c(0,1))
lines(ft$parm$x,ft$parm$S_c1_t, lty=3, col="gray")
lines(ft$parm$x,ft$parm$pi1_t,  lty=4, col="gray")

 plot(ft$parm$x, ft$parm$weight_k_cox,  type="l", lwd=3, col="red", ylim=c(0,1))
lines(ft$parm$x, ft$parm$weight_k_rmst, type="l", col="blue", ylim=c(0,1))
lines(ft$parm$x, ft$parm$weight_k_ah,   type="l", col="purple", ylim=c(0,1))
}
