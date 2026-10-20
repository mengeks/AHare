# Optional main-text figures. Every point comes from the existing saved rows.
source("R/utils_plot.R")
dir.create("output/figures", recursive=TRUE, showWarnings=FALSE)
mph <- readRDS("results/main_ph.rds")$scenarios
mnp <- readRDS("results/main_nonph.rds")$scenarios
cm <- readRDS("results/checkmate_sim.rds")
pairs <- c("drmst_cox","rah_cox","rah_drmst")
pair_labels <- c("D-RMST / Cox", "RAH / Cox", "RAH / D-RMST")
plot_panel <- function(row, x, xlabel, title, comparison, ticks=NULL, labels=NULL) {
  a <- row[[paste0("are_",comparison)]]
  e <- row[[paste0("ere_",comparison)]]
  ylim <- range(c(a,e,1)); pad <- max(diff(ylim)*.15,.045)
  plot(x,a,type=if(is.null(labels)) "b" else "p",pch=1,lwd=2,
       ylim=ylim+c(-pad,pad),xlab=xlabel,ylab="Relative efficiency",
       main=title,xaxt=if(is.null(ticks)) "s" else "n",cex=1.1)
  abline(h=1,col="grey70",lty=3)
  points(x,e,pch=16,col="#377eb8",cex=1.2)
  if(!is.null(ticks)) axis(1,at=ticks,labels=if(is.null(labels))ticks else labels)
}
begin_plot <- function(path,rows=2,height=7.5) {
  pdf(path,width=12,height=height)
  paper_par(mfrow=c(rows,3),mar=c(4.4,4.5,3,1),oma=c(0,0,2.1,0))
}
finish_plot <- function() {
  mtext("ARE: open circles and black line     ERE: filled blue circles     Reference line: 1",
        outer=TRUE,side=3,line=.4,cex=1.05)
  dev.off()
}
for (parameter in c("s0","shape")) {
  z <- if(parameter=="s0") mph[mph$shape==.826,] else mph[mph$s0==.5,]
  begin_plot(paste0("output/figures/summary-ph-",parameter,".pdf"))
  for(cn in c("light","heavy")) for(j in seq_along(pairs)) {
    row <- z[z$censoring==cn,]; row <- row[order(row[[parameter]]),]
    plot_panel(row,row[[parameter]],if(parameter=="s0") expression(S[0](40)) else expression(kappa),
               paste(if(cn=="light") "Light censoring" else "Heavy censoring",pair_labels[j],sep="\n"),
               comparison=pairs[j],
               ticks=row[[parameter]])
  }
  finish_plot()
}
begin_plot("output/figures/summary-nonph.pdf")
for(cn in c("light","heavy")) for(j in seq_along(pairs)) {
  row <- mnp[mnp$censoring==cn,]; row <- row[match(c("fading","delayed"),row$case),]
  plot_panel(row,1:2,"Treatment-effect pattern",
             paste(if(cn=="light") "Light censoring" else "Heavy censoring",pair_labels[j],sep="\n"),
             comparison=pairs[j],
             ticks=1:2,labels=c("Fading","Delayed"))
}
finish_plot()
begin_plot("output/figures/summary-checkmate-sensitivity.pdf",rows=3,height=10)
for(panel in c("tau","dropout","hazard")) for(j in seq_along(pairs)) {
  views <- cm$sensitivity_views[cm$sensitivity_views$panel==panel,]
  row <- cm$sensitivity[match(views$id,cm$sensitivity$id),]
  if(panel=="tau") plot_panel(row,row$tau,"Horizon (months)",pair_labels[j],pairs[j],ticks=row$tau)
  if(panel=="dropout") plot_panel(row,row$lambda_c,"Dropout rate (per month)",pair_labels[j],pairs[j],ticks=row$lambda_c)
  if(panel=="hazard") plot_panel(row,1:2,"Hazard structure",pair_labels[j],pairs[j],ticks=1:2,labels=c("Fitted non-PH","PH"))
}
finish_plot()
message("Wrote four optional summary figures from saved result objects")
