$(document).ready(function() {
    // Theme Management
    const root = document.documentElement;
    const themeToggle = document.getElementById("themeToggle");
    const darkIcon = document.getElementById("darkIcon");
    const lightIcon = document.getElementById("lightIcon");
    const themeText = document.getElementById("themeText");

    // Load saved theme or default to light
    const savedTheme = localStorage.getItem("theme") || "light";
    applyTheme(savedTheme);

    function applyTheme(theme) {
        root.setAttribute("data-theme", theme);
        localStorage.setItem("theme", theme);

        if (theme === "dark") {
            darkIcon.style.display = "none";
            lightIcon.style.display = "inline";
            themeText.textContent = "Light Mode";
        } else {
            darkIcon.style.display = "inline";
            lightIcon.style.display = "none";
            themeText.textContent = "Dark Mode";
        }
    }

    // Toggle theme on button click
    themeToggle.addEventListener("click", function() {
        const currentTheme = root.getAttribute("data-theme");
        const newTheme = currentTheme === "light" ? "dark" : "light";
        applyTheme(newTheme);
    });

    // Initialize DataTable with column filters and export buttons
    var table = $(".table").DataTable({
        pageLength: 25,
        lengthMenu: [[10, 25, 50, 100, 500, -1], ["10 rows", "25 rows", "50 rows", "100 rows", "500 rows", "Show all"]],
        order: [[0, "asc"]],
        responsive: true,
        dom: "<\"row mb-3\"<\"col-sm-12 col-md-6\"l><\"col-sm-12 col-md-6 text-end\"B>>" +
             "<\"row\"<\"col-sm-12 col-md-6\"f><\"col-sm-12 col-md-6 text-end\"<\"clear-filters\">>>" +
             "<\"row\"<\"col-sm-12\"tr>>" +
             "<\"row\"<\"col-sm-12 col-md-5\"i><\"col-sm-12 col-md-7\"p>>",
        buttons: [
            {
                extend: "excel",
                text: "<i class=\"fas fa-file-excel\"></i> Excel",
                className: "btn btn-success btn-sm me-1",
                title: "Procmon Analysis - " + new Date().toISOString().split("T")[0],
                exportOptions: { orthogonal: "export" }
            },
            {
                extend: "csv",
                text: "<i class=\"fas fa-file-csv\"></i> CSV",
                className: "btn btn-info btn-sm me-1",
                title: "Procmon Analysis - " + new Date().toISOString().split("T")[0],
                exportOptions: { orthogonal: "export" }
            },
            {
                extend: "pdf",
                text: "<i class=\"fas fa-file-pdf\"></i> PDF",
                className: "btn btn-danger btn-sm me-1",
                title: "Procmon Analysis",
                orientation: "landscape",
                pageSize: "LEGAL",
                exportOptions: { orthogonal: "export" }
            },
            {
                extend: "copy",
                text: "<i class=\"fas fa-copy\"></i> Copy",
                className: "btn btn-secondary btn-sm me-1",
                exportOptions: { orthogonal: "export" }
            },
            {
                extend: "print",
                text: "<i class=\"fas fa-print\"></i> Print",
                className: "btn btn-dark btn-sm",
                exportOptions: { orthogonal: "export" }
            }
        ],
        initComplete: function() {
            // Add column-specific checkbox filter dropdowns
            this.api().columns().every(function(colIdx) {
                var column = this;
                var title = $(column.header()).text();

                // Create filter container
                var filterContainer = $("<div style=\"position: relative;\"></div>").appendTo($(column.header()).empty());

                // Create filter button
                var filterBtn = $("<button class=\"column-filter-btn\" type=\"button\">" +
                    "<span class=\"filter-text\">" + title + "</span>" +
                    "<i class=\"fas fa-chevron-down\"></i>" +
                    "</button>").appendTo(filterContainer);

                // Create dropdown
                var dropdown = $("<div class=\"column-filter-dropdown\"></div>").appendTo(filterContainer);

                // Add search box
                var searchBox = $("<div class=\"filter-search\"><input type=\"text\" placeholder=\"Search...\" class=\"filter-search-input\"></div>").appendTo(dropdown);

                // Create options container
                var optionsContainer = $("<div class=\"filter-options\"></div>").appendTo(dropdown);

                // Get unique values sorted
                var uniqueValues = [];
                column.data().unique().sort().each(function(d) {
                    if (d) uniqueValues.push(d);
                });

                // Add checkbox options
                uniqueValues.forEach(function(value) {
                    var optionId = "filter_" + colIdx + "_" + value.replace(/[^a-zA-Z0-9]/g, "_");
                    var option = $("<div class=\"filter-option\">" +
                        "<input type=\"checkbox\" id=\"" + optionId + "\" value=\"" + value + "\" checked>" +
                        "<label for=\"" + optionId + "\">" + value + "</label>" +
                        "</div>");
                    optionsContainer.append(option);
                });

                // Add action buttons
                var actions = $("<div class=\"filter-actions\">" +
                    "<button class=\"select-all-btn\">Select All</button>" +
                    "<button class=\"clear-btn\">Clear</button>" +
                    "</div>").appendTo(dropdown);

                // Toggle dropdown
                filterBtn.on("click", function(e) {
                    e.stopPropagation();
                    $(".column-filter-dropdown").not(dropdown).removeClass("show");
                    dropdown.toggleClass("show");
                });

                // Search functionality
                searchBox.find("input").on("keyup", function() {
                    var searchTerm = $(this).val().toLowerCase();
                    optionsContainer.find(".filter-option").each(function() {
                        var text = $(this).find("label").text().toLowerCase();
                        $(this).toggle(text.indexOf(searchTerm) > -1);
                    });
                });

                // Checkbox change handler
                optionsContainer.on("change", "input[type=\"checkbox\"]", function() {
                    var selectedValues = [];
                    optionsContainer.find("input[type=\"checkbox\"]:checked").each(function() {
                        selectedValues.push($.fn.dataTable.util.escapeRegex($(this).val()));
                    });

                    // Update filter
                    if (selectedValues.length === uniqueValues.length || selectedValues.length === 0) {
                        column.search("").draw();
                    } else {
                        column.search("^(" + selectedValues.join("|") + ")$", true, false).draw();
                    }

                    // Update button text with count
                    var checkedCount = optionsContainer.find("input[type=\"checkbox\"]:checked").length;
                    if (checkedCount < uniqueValues.length) {
                        filterBtn.find(".filter-text").html(title + " <span class=\"filter-count\">" + checkedCount + "</span>");
                    } else {
                        filterBtn.find(".filter-text").text(title);
                    }
                });

                // Select All button
                actions.find(".select-all-btn").on("click", function(e) {
                    e.stopPropagation();
                    optionsContainer.find("input[type=\"checkbox\"]").prop("checked", true).first().trigger("change");
                });

                // Clear button
                actions.find(".clear-btn").on("click", function(e) {
                    e.stopPropagation();
                    optionsContainer.find("input[type=\"checkbox\"]").prop("checked", false).first().trigger("change");
                });
            });

            // Close dropdowns when clicking outside
            $(document).on("click", function() {
                $(".column-filter-dropdown").removeClass("show");
            });

            // Add "Clear All Filters" button
            $("div.clear-filters").html("<button id=\"clearFiltersBtn\" class=\"btn btn-warning btn-sm\"><i class=\"fas fa-eraser\"></i> Clear All Filters</button>");

            // Initialize Search Enhancement Module
            if (window.SearchEnhancement) {
                SearchEnhancement.init(table);
            }
        }
    });

    // Clear all filters functionality
    $(document).on("click", "#clearFiltersBtn", function() {
        // Reset all column checkbox filters
        table.columns().every(function() {
            var header = $(this.header());
            // Check all checkboxes in this column
            header.find("input[type=\"checkbox\"]").prop("checked", true);
            // Clear the column search
            this.search("");
            // Update button text to remove filter count
            var title = header.find(".filter-text").text().split(" ")[0];
            header.find(".filter-text").text(title);
        });
        // Reset main search and redraw
        table.search("").draw();
    });

    // Row click handler for detail view
    $(".table tbody").on("click", "tr", function() {
        var rowData = table.row(this).data();
        if (rowData) {
            showRowDetails(rowData);
        }
    });

    // Function to display row details in modal
    function showRowDetails(rowData) {
        var detailHtml = "";
        var columnNames = [];
        $(".table thead th").each(function(index) {
            if (index > 0) {
                columnNames.push($(this).text().trim().split(" ")[0]);
            }
        });
        rowData.forEach(function(value, index) {
            if (index > 0) {
                var fieldName = columnNames[index - 1] || "Field " + index;
                var fieldValue = value || "(empty)";
                detailHtml += "<div class=\"detail-item\">";
                detailHtml += "  <div class=\"label\">" + fieldName + "</div>";
                detailHtml += "  <div class=\"value\">" + fieldValue + "</div>";
                detailHtml += "</div>";
            }
        });
        $("#detailContent").html(detailHtml);
        $("#rowDetailModal").modal("show");
    }

    // Professional Color Palette
    const colorPalette = [
        "rgba(102, 126, 234, 0.8)", "rgba(118, 75, 162, 0.8)", "rgba(40, 167, 69, 0.8)",
        "rgba(255, 193, 7, 0.8)", "rgba(220, 53, 69, 0.8)", "rgba(23, 162, 184, 0.8)",
        "rgba(108, 117, 125, 0.8)", "rgba(255, 99, 132, 0.8)", "rgba(54, 162, 235, 0.8)",
        "rgba(255, 206, 86, 0.8)", "rgba(75, 192, 192, 0.8)", "rgba(153, 102, 255, 0.8)",
        "rgba(255, 159, 64, 0.8)", "rgba(201, 203, 207, 0.8)", "rgba(255, 99, 71, 0.8)"
    ];

    // Chart instances
    let processChartInstance = null;
    let operationChartInstance = null;
    let processThumbnailInstance = null;
    let operationThumbnailInstance = null;

    // Initialize thumbnail charts on page load
    const processThumbnailCanvas = document.getElementById("processThumbnail");
    if (processThumbnailCanvas) {
        const labels = processThumbnailCanvas.dataset.labels.split(",");
        const data = processThumbnailCanvas.dataset.data.split(",").map(Number);
        processThumbnailInstance = createChart(processThumbnailCanvas, labels, data, "bar", colorPalette[0]);
    }

    const operationThumbnailCanvas = document.getElementById("operationThumbnail");
    if (operationThumbnailCanvas) {
        const labels = operationThumbnailCanvas.dataset.labels.split(",");
        const data = operationThumbnailCanvas.dataset.data.split(",").map(Number);
        operationThumbnailInstance = createChart(operationThumbnailCanvas, labels, data, "doughnut", colorPalette[1]);
    }

    // Initialize charts when modals open
    $("#processChartModal").on("shown.bs.modal", function() {
        if (!processChartInstance) {
            const canvas = document.getElementById("processChart");
            const labels = canvas.dataset.labels.split(",");
            const data = canvas.dataset.data.split(",").map(Number);
            processChartInstance = createChart(canvas, labels, data, "bar", colorPalette[0]);
        }
    });

    $("#operationChartModal").on("shown.bs.modal", function() {
        if (!operationChartInstance) {
            const canvas = document.getElementById("operationChart");
            const labels = canvas.dataset.labels.split(",");
            const data = canvas.dataset.data.split(",").map(Number);
            operationChartInstance = createChart(canvas, labels, data, "bar", colorPalette[1]);
        }
    });

    // Create chart function with professional config
    function createChart(canvas, labels, data, type, primaryColor) {
        const colors = type === "bar" ? data.map(() => primaryColor) : colorPalette.slice(0, data.length);
        return new Chart(canvas, {
            type: type,
            data: {
                labels: labels,
                datasets: [{
                    label: "Event Count",
                    data: data,
                    backgroundColor: colors,
                    borderColor: colors.map(c => c.replace("0.8", "1")),
                    borderWidth: 2,
                    hoverOffset: 10
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                animation: { duration: 1000, easing: "easeInOutQuart" },
                plugins: {
                    legend: {
                        display: type !== "bar",
                        position: "top",
                        onClick: (e, legendItem, legend) => {
                            const index = legendItem.index;
                            const chart = legend.chart;
                            const meta = chart.getDatasetMeta(0);
                            meta.data[index].hidden = !meta.data[index].hidden;
                            chart.update();
                        }
                    },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                const label = context.label || "";
                                const value = context.parsed.y || context.parsed;
                                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                const percentage = ((value / total) * 100).toFixed(1);
                                return label + ": " + value.toLocaleString() + " (" + percentage + "%)";
                            }
                        }
                    }
                },
                scales: type === "bar" ? {
                    y: { beginAtZero: true, ticks: { precision: 0 } }
                } : {}
            }
        });
    }

    // Chart type switching
    $(".chart-type-btn").on("click", function() {
        const chartName = $(this).data("chart");
        const newType = $(this).data("type");
        const canvas = document.getElementById(chartName + "Chart");
        const labels = canvas.dataset.labels.split(",");
        const data = canvas.dataset.data.split(",").map(Number);
        const primaryColor = chartName === "process" ? colorPalette[0] : colorPalette[1];

        // Destroy existing chart
        if (chartName === "process" && processChartInstance) {
            processChartInstance.destroy();
            processChartInstance = createChart(canvas, labels, data, newType, primaryColor);
        } else if (chartName === "operation" && operationChartInstance) {
            operationChartInstance.destroy();
            operationChartInstance = createChart(canvas, labels, data, newType, primaryColor);
        }

        // Update button states
        $(this).siblings().removeClass("active");
        $(this).addClass("active");
    });

    // Download chart as PNG
    $("#downloadProcessChart").on("click", function() {
        if (processChartInstance) {
            const url = processChartInstance.toBase64Image();
            const a = document.createElement("a");
            a.href = url;
            a.download = "process-chart-" + new Date().toISOString().split("T")[0] + ".png";
            a.click();
        }
    });

    $("#downloadOperationChart").on("click", function() {
        if (operationChartInstance) {
            const url = operationChartInstance.toBase64Image();
            const a = document.createElement("a");
            a.href = url;
            a.download = "operation-chart-" + new Date().toISOString().split("T")[0] + ".png";
            a.click();
        }
    });
});

