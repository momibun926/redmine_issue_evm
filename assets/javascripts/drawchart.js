function drawChart(dataToChart, placeholder, nowdate, graphtitle){ 
    var data = dataToChart;
    var chartOptions = {
            credits:{
                enabled: false
            },
            chart:{
                renderTo: placeholder,
                type: 'line',
                zoomType: 'x'
            },
            title:{
                text: graphtitle,
                align: 'left'
            },
            xAxis:{
                type: 'datetime',
                dateTimeLabelFormats:{
                    day: '%b-%e',
                    week: '%b-%e',
                    month: '%b-%y',
                    year: '%Y'
                },
                minTickInterval: 24 * 3600 * 1000,
                tickmarkPlacement: 'on',
                plotLines: [{
                    color: '#FFAAAA',
                    width: 2,
                    value: nowdate,
                    label: {
                        text: 'Project is here',
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
                },
                {
                    name: 'BAC', 
                    dashStyle: 'dash',
                    lineWidth: 1,
                    data: data.bac_top_line
                },
                {
                    name: 'EAC', 
                    dashStyle: 'dash',
                    lineWidth: 1,
                    data: data.eac_top_line
                },
                {
                    name: 'AC Forecast',
                    color: '#fcb040', 
                    dashStyle: 'dot',
                    data: data.actual_cost_forecast
                },
                {
                    name: 'EV Forecast', 
                    color: '#8cc63f',
                    dashStyle: 'dot',
                    data: data.earned_value_forecast
                }
            ]
      };
      var lg1 = new Highcharts.Chart(chartOptions);
}
function drawChartPerformance(dataToChart, placeholder, graphtitle){ 
    var data = dataToChart;
    var chartOptions = {
            credits:{
                enabled: false
            },
            chart:{
                renderTo: placeholder,
                type: 'line',
                zoomType: 'x'
            },
            title:{
                text: graphtitle,
                align: 'left'
            },
            xAxis:{
                type: 'datetime',
                dateTimeLabelFormats:{
                    day: '%b-%e',
                    week: '%b-%e',
                    month: '%b-%y',
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
                    color: '#0f75bc',
                    data: data.cr
                }
            ]
      };
      var lg1 = new Highcharts.Chart(chartOptions);
}

