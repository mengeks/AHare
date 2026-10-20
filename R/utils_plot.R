PAPER_STYLE <- list(
  colors = c(Cox = "#D73027", DRMST = "#4575B4", RAH = "#1A9850", Signal = "black"),
  lty = c(Cox = 1, DRMST = 2, RAH = 3, Signal = 2),
  labels = c(Cox = "Cox", DRMST = "D-RMST", RAH = "RAH", Signal = "Signal")
)

paper_par <- function(...) {
  par(cex.axis = 1.15, cex.lab = 1.25, cex.main = 1.2, ...)
}
