// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
// options for timeline plots

var dashboard_opts = {
	colors: ['#08c'],
	shadowSize:0,
	lines:{fill:true},
	grid: {color:'#fff',margin:0},
	xaxis: { mode: "time",color:'#222',tickLength:1,ticks:4,timeformat: "%y-%m-%d %Hh" },
	yaxis: { show: false}
};

var sourcelist_opts = {
	colors: ['#08c'],
	shadowSize:0,
	lines:{fill:true},
	grid: {color:'#fff',margin:0},
	xaxis: { mode: "time",show:false },
	yaxis: { show: false}
};

$('.delete').live('click',
function(event) {
    if (confirm("This action can result in data loss. Are you sure?"))
    return true;
});





