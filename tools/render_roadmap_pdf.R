args <- commandArgs(trailingOnly = TRUE)
input_path <- if (length(args) >= 1) args[[1]] else file.path("docs", "ROADMAP.md")
output_path <- if (length(args) >= 2) args[[2]] else file.path("docs", "ROADMAP.pdf")

lines <- readLines(input_path, warn = FALSE, encoding = "UTF-8")

normalise_line <- function(line) {
  if (grepl("^#+\\s+", line)) {
    heading <- gsub("^#+\\s*", "", line)
    return(c("", toupper(heading), strrep("-", nchar(heading)), ""))
  }

  if (grepl("^-\\s+", line)) {
    return(sub("^-\\s+", "* ", line))
  }

  line
}

normalised <- unlist(lapply(lines, normalise_line), use.names = FALSE)

wrapped <- unlist(
  lapply(normalised, function(line) {
    if (!nzchar(line)) {
      return("")
    }

    if (grepl("^\\*\\s+", line)) {
      return(strwrap(line, width = 92, indent = 0, exdent = 2))
    }

    strwrap(line, width = 92)
  }),
  use.names = FALSE
)

lines_per_page <- 50
page_count <- max(1, ceiling(length(wrapped) / lines_per_page))

grDevices::pdf(output_path, width = 8.27, height = 11.69, family = "Helvetica")

for (page in seq_len(page_count)) {
  start <- ((page - 1) * lines_per_page) + 1
  end <- min(page * lines_per_page, length(wrapped))
  page_lines <- wrapped[start:end]

  graphics::plot.new()
  graphics::par(mar = c(0, 0, 0, 0))
  graphics::plot.window(xlim = c(0, 1), ylim = c(0, 1))
  graphics::text(
    x = 0.04,
    y = 0.97,
    labels = "AMR Cartography Package Roadmap",
    adj = c(0, 1),
    font = 2,
    cex = 1.1
  )

  y_positions <- seq(0.93, 0.05, length.out = max(length(page_lines), 1))

  for (i in seq_along(page_lines)) {
    graphics::text(
      x = 0.04,
      y = y_positions[i],
      labels = page_lines[i],
      adj = c(0, 1),
      cex = 0.83
    )
  }

  graphics::text(
    x = 0.96,
    y = 0.02,
    labels = sprintf("Page %s", page),
    adj = c(1, 0),
    cex = 0.75
  )
}

grDevices::dev.off()
