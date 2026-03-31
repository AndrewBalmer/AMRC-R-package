vignettes <- c(
  "vignettes/using-your-own-mic-data.Rmd",
  "vignettes/advanced-feature-and-mixed-model-analysis.Rmd",
  "vignettes/external-data-structures.Rmd",
  "vignettes/end-to-end-spneumoniae.Rmd"
)

for (path in vignettes) {
  message("Rendering ", path)
  rmarkdown::render(
    input = path,
    output_dir = tempdir(),
    intermediates_dir = tempdir(),
    envir = new.env(parent = globalenv()),
    quiet = TRUE
  )
}

message("All vignettes rendered successfully.")
