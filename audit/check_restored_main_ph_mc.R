# Reuse the previously verified raw point contrasts; restore rmst2's NA mask.
private <- "/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare"
shared <- "/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/Efficient and Debiased Learning of Average Hazard Under Non-Proportional Hazards (1)/AHare"
setwd(shared)
if (dir.exists(".library")) .libPaths(c(normalizePath(".library"), .libPaths()))
source("R/utils_pipeline.R")
cfg <- read_pipeline_config()
rows <- readRDS("results/main_ph.rds")$scenarios
previous <- readRDS(file.path(private,"audit/main_ph_seed_mc_replay.rds"))
current <- previous$current
prior_check <- previous$comparison
ratio <- function(m) efficacy(m[,"RAH"])/efficacy(m[,"DRMST"])
for (id in rows$id) {
  row <- rows[rows$id==id,]
  if(abs(ratio(current[[id]])-row$ere_rah_drmst)>1e-10) {
    message("Restoring public rmst2 support mask: ",id)
    values <- unlist(parallel::mclapply(seq_len(row$B),function(i) {
      set.seed(row$seed+i-1L)
      dat <- gen_ph_dataset(row$n,row$shape,row$scale0,row$scale1,
                             row$lambda_c,cfg$simulation$censoring_uniform)
      tryCatch(survRM2::rmst2(dat$time,dat$status,dat$arm,tau=row$tau)$unadjusted.result[1,1],
               error=function(e) NA_real_)
    },mc.cores=4))
    keep <- is.finite(values)
    stopifnot(max(abs(values[keep]-current[[id]][keep,"DRMST"]))<1e-10)
    current[[id]][,"DRMST"] <- values
  }
  stopifnot(abs(ratio(current[[id]])-row$ere_rah_drmst)<1e-10)
}
bootstrap_se <- function(m,seed) {
  set.seed(seed)
  sd(replicate(2000,ratio(m[sample.int(nrow(m),nrow(m),replace=TRUE),,drop=FALSE])))
}
out <- list()
for(i in seq_len(nrow(prior_check))) {
  info <- prior_check[i,]
  shape <- if(info$table==3) as.numeric(sub("shape=([^;]+).*","\\1",info$setting)) else .826
  s0 <- if(info$table==2) as.numeric(sub("s0=([^;]+).*","\\1",info$setting)) else .5
  row <- rows[rows$shape==shape & rows$s0==s0 &
    rows$censoring==sub(".*;","",info$setting),]
  stopifnot(nrow(row)==1L)
  old <- read.csv(file.path(private,info$legacy_file))
  m <- as.matrix(old[,c("st_rmst","st_rah")]); colnames(m)<-c("DRMST","RAH")
  new <- current[[row$id]]
  se0 <- bootstrap_se(m,27301); se1<-bootstrap_se(new,27302)
  z <- (ratio(new)-ratio(m))/sqrt(se0^2+se1^2)
  out[[i]] <- data.frame(table=info$table,setting=info$setting,old=ratio(m),new=ratio(new),
    old_mc_se=se0,new_mc_se=se1,combined_mc_z=z,within_nominal_95_mc_band=abs(z)<=1.96,
    old_drmst_finite=sum(is.finite(m[,"DRMST"])),new_drmst_finite=sum(is.finite(new[,"DRMST"])),
    seed_only=TRUE)
}
out <- do.call(rbind,out)
write.csv(out,file.path(private,"audit/restored_main_ph_mc_check.csv"),row.names=FALSE)
saveRDS(list(current=current,comparison=out),file.path(private,"audit/restored_main_ph_mc_replay.rds"))
print(out[,c("table","setting","old","new","combined_mc_z","within_nominal_95_mc_band")],row.names=FALSE)
