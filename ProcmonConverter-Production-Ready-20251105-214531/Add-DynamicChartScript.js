// Dynamic Chart Update Enhancement for Procmon Reports
// This script adds real-time chart updates based on DataTable filters

(function() {
    'use strict';

    // Store original data
    let originalProcessData = null;
    let originalOperationData = null;
    let currentProcessType = 'bar';
    let currentOperationType = 'bar';

    // Column indices for process and operation data (will be auto-detected)
    let processColumnIndex = -1;
    let operationColumnIndex = -1;

    /**
     * Detects which columns contain process names and operations
     */
    function detectDataColumns() {
        const table = $('.table').DataTable();
        const columnNames = [];

        $('.table thead th').each(function(index) {
            if (index > 0) { // Skip the # column
                const headerText = $(this).text().trim().toLowerCase();
                columnNames.push({index: index - 1, name: headerText}); // -1 because we're skipping #
            }
        });

        // Look for process column (common names)
        const processPatterns = ['process', 'processname', 'process name', 'proc'];
        processColumnIndex = columnNames.findIndex(col =>
            processPatterns.some(pattern => col.name.includes(pattern))
        );

        // Look for operation column (common names)
        const operationPatterns = ['operation', 'op', 'operationtype', 'operation type'];
        operationColumnIndex = columnNames.findIndex(col =>
            operationPatterns.some(pattern => col.name.includes(pattern))
        );

        console.log('Detected columns:', {processColumnIndex, operationColumnIndex});

        return processColumnIndex >= 0 && operationColumnIndex >= 0;
    }

    /**
     * Aggregates data from visible (filtered) rows
     */
    function aggregateFilteredData() {
        const table = $('.table').DataTable();
        const processCount = {};
        const operationCount = {};

        // Get filtered/visible data
        table.rows({filter: 'applied'}).every(function() {
            const rowData = this.data();

            if (processColumnIndex >= 0 && rowData[processColumnIndex + 1]) {
                const process = rowData[processColumnIndex + 1];
                processCount[process] = (processCount[process] || 0) + 1;
            }

            if (operationColumnIndex >= 0 && rowData[operationColumnIndex + 1]) {
                const operation = rowData[operationColumnIndex + 1];
                operationCount[operation] = (operationCount[operation] || 0) + 1;
            }
        });

        return {
            processes: processCount,
            operations: operationCount,
            totalRows: table.rows({filter: 'applied'}).count()
        };
    }

    /**
     * Converts aggregated data to top N items
     */
    function getTopItems(dataObj, topN = 15) {
        return Object.entries(dataObj)
            .sort((a, b) => b[1] - a[1])
            .slice(0, topN)
            .reduce((acc, [key, value]) => {
                acc.labels.push(key);
                acc.data.push(value);
                return acc;
            }, {labels: [], data: []});
    }

    /**
     * Updates a chart with new data
     */
    function updateChart(chartInstance, newData, chartType, primaryColor, colorPalette) {
        if (!chartInstance) return null;

        const colors = chartType === 'bar'
            ? newData.data.map(() => primaryColor)
            : colorPalette.slice(0, newData.data.length);

        // Destroy and recreate with new data
        const canvas = chartInstance.canvas;
        chartInstance.destroy();

        return new Chart(canvas, {
            type: chartType,
            data: {
                labels: newData.labels,
                datasets: [{
                    label: 'Event Count',
                    data: newData.data,
                    backgroundColor: colors,
                    borderColor: colors.map(c => c.replace('0.8', '1')),
                    borderWidth: 2,
                    hoverOffset: 10
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                animation: {duration: 750, easing: 'easeInOutQuart'},
                plugins: {
                    legend: {
                        display: chartType !== 'bar',
                        position: 'top',
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
                                const label = context.label || '';
                                const value = context.parsed.y || context.parsed;
                                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                const percentage = total > 0 ? ((value / total) * 100).toFixed(1) : '0.0';
                                return label + ': ' + value.toLocaleString() + ' (' + percentage + '%)';
                            }
                        }
                    },
                    title: {
                        display: true,
                        text: newData.data.length > 0
                            ? `Showing filtered data (${newData.data.reduce((a,b) => a+b, 0).toLocaleString()} events)`
                            : 'No data available',
                        font: {size: 14, weight: 'bold'}
                    }
                },
                scales: chartType === 'bar' ? {
                    y: {beginAtZero: true, ticks: {precision: 0}}
                } : {}
            }
        });
    }

    /**
     * Initializes the dynamic chart enhancement
     */
    function init() {
        console.log('Initializing dynamic chart enhancement...');

        // Wait for DataTable and charts to be ready
        const checkReady = setInterval(function() {
            if (typeof table !== 'undefined' && table.rows().count() > 0) {
                clearInterval(checkReady);

                // Detect columns
                if (!detectDataColumns()) {
                    console.warn('Could not auto-detect process/operation columns');
                    return;
                }

                // Store original chart data
                const processCanvas = document.getElementById('processChart');
                const operationCanvas = document.getElementById('operationChart');

                if (processCanvas && originalProcessData === null) {
                    originalProcessData = {
                        labels: processCanvas.dataset.labels.split(','),
                        data: processCanvas.dataset.data.split(',').map(Number)
                    };
                }

                if (operationCanvas && originalOperationData === null) {
                    originalOperationData = {
                        labels: operationCanvas.dataset.labels.split(','),
                        data: operationCanvas.dataset.data.split(',').map(Number)
                    };
                }

                // Listen to DataTable draw event
                table.on('draw', function() {
                    const aggregated = aggregateFilteredData();
                    const totalVisible = aggregated.totalRows;
                    const totalRows = table.rows().count();

                    console.log(`Filter update: ${totalVisible} of ${totalRows} rows visible`);

                    // Determine if we should use filtered or original data
                    const useFiltered = totalVisible < totalRows;

                    // Update process chart if it exists
                    if (processChartInstance && originalProcessData) {
                        const processData = useFiltered
                            ? getTopItems(aggregated.processes, 15)
                            : originalProcessData;

                        processChartInstance = updateChart(
                            processChartInstance,
                            processData,
                            currentProcessType,
                            colorPalette[0],
                            colorPalette
                        );
                    }

                    // Update operation chart if it exists
                    if (operationChartInstance && originalOperationData) {
                        const operationData = useFiltered
                            ? getTopItems(aggregated.operations, 15)
                            : originalOperationData;

                        operationChartInstance = updateChart(
                            operationChartInstance,
                            operationData,
                            currentOperationType,
                            colorPalette[1],
                            colorPalette
                        );
                    }
                });

                // Hook into chart type switching to remember current type
                $('.chart-type-btn').on('click', function() {
                    const chartName = $(this).data('chart');
                    const newType = $(this).data('type');

                    if (chartName === 'process') {
                        currentProcessType = newType;
                    } else if (chartName === 'operation') {
                        currentOperationType = newType;
                    }
                });

                console.log('Dynamic chart enhancement activated!');

                // Add indicator badge
                $('.chart-container h3').append(
                    ' <span class="badge bg-success ms-2" style="font-size: 0.6em; vertical-align: middle;">Live Updates</span>'
                );
            }
        }, 500);

        // Timeout after 10 seconds
        setTimeout(function() {
            clearInterval(checkReady);
        }, 10000);
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();

