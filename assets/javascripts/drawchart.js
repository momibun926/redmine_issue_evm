function drawChartjs(rrr){
    var plotData = rrr
    var myChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: plotData.labels,
            datasets: [{
                label: "PV",
                spanGaps: true,
                data: [plotData.pv],
                borderWidth: 2,
                lineTension: 0,
                borderColor: "dodgerblue",
                pointRadius: 0,
                backgroundColor: "dodgerblue",
                fill: false
            },{
                label: "EV",
                spanGaps: true,
                data: [plotData.ev],
                borderWidth: 2,
                lineTension: 0,
                borderColor: "limegreen",
                pointRadius: 0,
                backgroundColor: "limegreen",
                fill: false
            },{
                label: "AC",
                spanGaps: true,
                data: [plotData.ac],
                borderWidth: 2,
                lineTension: 0,
                borderColor: "Orange",
                pointRadius: 0,
                backgroundColor: "Orange",
                fill: false
            },{
                label: "PV Daily",
                data: [plotData.pv_daily],
                borderWidth: 2,
                borderColor: "Orange",
                backgroundColor: "Orange"
            },{
                label: "Baseline",
                spanGaps: true,
                data: [plotData.baseline],
                borderWidth: 2,
                lineTension: 0,
                borderColor: "Navy",
                pointRadius: 0,
                backgroundColor: "Navy",
                fill: false
            },{
                label: "BAC",
                spanGaps: true,
                data: [plotData.bac],
                borderDash: [8, 2],
                borderWidth: 2,
                lineTension: 0,
                borderColor: "Navy",
                pointRadius: 0,
                backgroundColor: "Navy",
                fill: false
            },{
                label: "EAC",
                spanGaps: true,
                data: [plotData.eac],
                borderDash: [8, 2],
                borderWidth: 2,
                lineTension: 0,
                borderColor: "Navy",
                pointRadius: 0,
                backgroundColor: "Navy",
                fill: false
            },{
                label: "AC Forecast",
                spanGaps: true,
                data: [plotData.ac_forecast],
                borderDash: [8, 2],
                borderWidth: 2,
                lineTension: 0,
                borderColor: "Orange",
                pointRadius: 0,
                backgroundColor: "Orange",
                fill: false
            },{
                label: "EV Forecast",
                spanGaps: true,
                data: [plotData.ev_forecast],
                borderDash: [8, 2],
                borderWidth: 2,
                lineTension: 0,
                borderColor: "limegreen",
                pointRadius: 0,
                backgroundColor: "limegreen",
                fill: false
            }]
        },
        options: {
            scales: {
                xAxes: [{
                    type: 'time',
                    distribution: 'linear',
                    ticks: {
                        source: 'data'
                    }
                }]
            }
        }
    });
}

function drawProjectChart(dataToChart, placeholder, nowdate, graphtitle){
    var data = dataToChart;
    var chartOptions = {
            credits:{
                enabled: false
            },
            chart:{
                renderTo: placeholder,
                zoomType: 'xy'
            },
            title:{
                text: graphtitle,
                align: 'left',
                style: {
                    fontSize: '1.2em'
                }
            },
            xAxis:{
                type: 'datetime',
                dateTimeLabelFormats:{
                    day: '%m-%d',
                    week: '%Y-%m-%d',
                    month: '%Y-%m-%d',
                    year: '%Y'
                },
                minTickInterval: 24 * 3600 * 1000,
                tickmarkPlacement: 'on',
                plotLines: [{
                    color: '#FFAAAA',
                    width: 2,
                    value: nowdate,
                    label: {
                        text: 'Basis date',
                        verticalAlign: 'bottom',
                        textAlign: 'right',
                        y: -10
                    }
                }]
            },
            yAxis:{
                title: {
                    text: 'Hours'
                }
            },
            tooltip:{
                valueDecimals: 2,
                crosshairs: true,
                shared: true
            },
            plotOptions:{
                line: {
                    lineWidth: 2,
                    states: {
                        hover: {
                            lineWidth: 3
                        }
                    },
                    marker: {
                        enabled: false
                    }
                },
                column: {
                    pointWidth: 10,
                    pointPadding: 0.2,
                    borderWidth: 0
                }
            },
            legend:{
                align: 'center',
                verticalAlign: 'bottom',
                borderWidth: 0,
                itemDistance: 50
            },
            series:[
                {
                    name: 'PV Daily',
                    type: 'column',
                    color: '#8acdfc',
                    data: data.planned_value_daily
                },
                {
                    name: 'PV Actual',
                    type: 'line',
                    color: '#0f75bc',
                    data: data.planned_value
                },
                {
                    name: 'PV Baseline',
                    type: 'line',
                    color: '#000033',
                    data: data.baseline_value
                },
                {
                    name: 'AC',
                    type: 'line',
                    color: '#fcb040',
                    data: data.actual_cost
                },
                {
                    name: 'EV',
                    type: 'line',
                    color: '#8cc63f',
                    data: data.earned_value
                },
                {
                    name: 'BAC',
                    type: 'line',
                    dashStyle: 'dash',
                    lineWidth: 1,
                    data: data.bac_top_line
                },
                {
                    name: 'EAC',
                    type: 'line',
                    dashStyle: 'dash',
                    lineWidth: 1,
                    data: data.eac_top_line
                },
                {
                    name: 'AC Forecast',
                    type: 'line',
                    color: '#fcb040',
                    dashStyle: 'dot',
                    data: data.actual_cost_forecast
                },
                {
                    name: 'EV Forecast',
                    type: 'line',
                    color: '#8cc63f',
                    dashStyle: 'dot',
                    data: data.earned_value_forecast
                }
            ]
      };
      Highcharts.setOptions({global : {useUTC : false}});
      var lg1 = new Highcharts.Chart(chartOptions);
}
function drawPerformanceChart(dataToChart, placeholder, graphtitle){
    var data = dataToChart;
    var chartOptions = {
            credits:{
                enabled: false
            },
            chart:{
                renderTo: placeholder,
                type: 'line',
                zoomType: 'xy'
            },
            title:{
                text: graphtitle,
                align: 'left',
                style: {
                    fontSize: '1.2em'
                }
            },
            xAxis:{
                type: 'datetime',
                dateTimeLabelFormats:{
                    day: '%m-%d',
                    week: '%Y-%m-%d',
                    month: '%Y-%m-%d',
                    year: '%Y'
                },
                minTickInterval: 24 * 3600 * 1000,
                tickmarkPlacement: 'on'
            },
            yAxis:{
                min: 0,
                minorGridLineWidth: 0,
                minorTickInterval: 'auto',
                minorTickLength: 10,
                minorTickWidth: 1,
                plotLines:[{
                    value: 0,
                    width: 1,
                    color: '#808080'
                }],
                plotBands: [{
                    from: 0.9,
                    to: 1.1,
                    color: 'rgba(68, 170, 213, 0.1)',
                    label:{
                        style:{color: '#606060'}
                    }
                }]
            },
            tooltip:{
                valueDecimals: 2,
                crosshairs: true,
                shared: true
            },
            plotOptions:{
                line: {
                    lineWidth: 2,
                    states: {
                        hover: {
                            lineWidth: 3
                        }
                    },
                    marker: {
                        enabled: false
                    }
                }
            },
            legend:{
                align: 'center',
                verticalAlign: 'bottom',
                borderWidth: 0,
                itemDistance: 50
            },
            series:[
                {
                    name: 'SPI',
                    color: '#8cc63f',
                    data: data.spi
                },
                {
                    name: 'CPI',
                    color: '#fcb040',
                    data: data.cpi
                },
                {
                    name: 'CR',
                    color: '#a80909',
                    data: data.cr
                }
            ]
      };
      Highcharts.setOptions({global : {useUTC : false}});
      var lg1 = new Highcharts.Chart(chartOptions);
}
function drawOtherEvmChart(dataToChart, placeholder, nowdate, graphtitle){
    var data = dataToChart;
    var chartOptions = {
            credits:{
                enabled: false
            },
            chart:{
                renderTo: placeholder,
                type: 'line',
                zoomType: 'xy'
            },
            title:{
                text: graphtitle,
                align: 'left',
                style: {
                    fontSize: '1.2em'
                }
            },
            xAxis:{
                type: 'datetime',
                dateTimeLabelFormats:{
                    day: '%m-%d',
                    week: '%Y-%m-%d',
                    month: '%Y-%m-%d',
                    year: '%Y'
                },
                minTickInterval: 24 * 3600 * 1000,
                tickmarkPlacement: 'on',
                plotLines: [{
                    color: '#FFAAAA',
                    width: 2,
                    value: nowdate,
                    label: {
                        text: 'Basis date',
                        verticalAlign: 'bottom',
                        textAlign: 'right',
                        y: -10
                    }
                }]
            },
            yAxis:{
                min: 0,
                minorGridLineWidth: 0,
                minorTickInterval: 'auto',
                minorTickLength: 10,
                minorTickWidth: 1,
                plotLines:[{
                    value: 0,
                    width: 1,
                    color: '#808080'
                }]
            },
            yAxis:{
                title: {
                    text: 'Hours'
                }
            },
            tooltip:{
                valueDecimals: 2,
                crosshairs: true,
                shared: true
            },
            plotOptions:{
                line: {
                    lineWidth: 2,
                    states: {
                        hover: {
                            lineWidth: 3
                        }
                    },
                    marker: {
                        enabled: false
                    }
                }
            },
            legend:{
                align: 'center',
                verticalAlign: 'bottom',
                borderWidth: 0,
                itemDistance: 50
            },
            series:[
                {
                    name: 'PV',
                    color: '#0f75bc',
                    data: data.planned_value
                },
                {
                    name: 'AC',
                    color: '#fcb040',
                    data: data.actual_cost
                },
                {
                    name: 'EV',
                    color: '#8cc63f',
                    data: data.earned_value
                }
            ]
      };
      Highcharts.setOptions({global : {useUTC : false}});
      var lg1 = new Highcharts.Chart(chartOptions);
}

