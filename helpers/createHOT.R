createHOT <- function(doseTable,drugDefaults)
{
  rownames(doseTable) <- 1:nrow(doseTable)
  HOT <- rhandsontable(
    doseTable,
    overflow = 'visible',
    rowHeaders = NULL,
    height = 400,
    selectCallback = FALSE
  ) %>%
    hot_col(
      col = "Drug",
      type = "dropdown",
      source = drugDefaults$Drug,
      strict = TRUE,
      halign = "htLeft",
      valign = "vtMiddle",
      allowInvalid = FALSE
    ) %>%
    hot_col(
      col = "Time",
      halign = "htRight"
    ) %>%
    hot_col(
      col = "Dose",
      type = "numeric",
      halign = "htRight",
      validator = "function(value, callback) {callback(true)}"
    ) %>%
    hot_col(
      col = "Units",
      type = "dropdown",
      source = list(""),
      strict = TRUE,
      halign = "htLeft",
      valign = "vtMiddle",
      allowInvalid=FALSE
    ) %>%
    hot_context_menu(allowRowEdit = TRUE, allowColEdit = FALSE) %>%
    hot_rows(rowHeights = 10) %>%
    hot_cols(colWidths = c(120, 70, 70, 120))

  # Set units on a per drug basis
  for (i in 1:nrow(doseTable))
  {
    cell <- list(row = i - 1, col = 3)
    if (!is.na(doseTable$Drug[i]) && doseTable$Drug[i] != "")
    {
      cell$source <- unlist(drugDefaults$Units[drugDefaults$Drug == doseTable$Drug[i]])
    } else {
      cell$source <- c("")
    }
    HOT$x$cell <- c(HOT$x$cell, list(cell))
  }

  HOT <- htmlwidgets::onRender(HOT,
"
function(el, x) {

  var hot = this.hot;
  // do this to avoid adding duplicate callbacks on re-render
  hot.removeHook('afterChange', changeHot);
  hot.addHook('afterChange', changeHot);
}
"
  )
  return(HOT)
}
