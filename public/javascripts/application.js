// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
// options for timeline plots
var tl_opts = {
    gridPadding: {
        right: 35
    },
    axes: {
        xaxis: {
            renderer: $.jqplot.DateAxisRenderer,
            tickOptions: {
                formatString: '%Y-%m-%d',
                showMark: true,
                showGridline: false
            },
            pad: 0,
            numberTicks: 5
        },
        yaxis: {
            show: false,
            min: 0,
            tickOptions: {
                show: false
            },
        },
        x2axis: {
            show: false
        },
        y2axis: {
            show: false
        }
    },
    series: [{
        lineWidth: 2,
        showMarker: false,
        color: '#006295',
        shadow: false
    }],
    grid: {
        drawGridLines: false,
        borderWidth: 0,
        shadow: false,
        background: 'transparent'
    }
};

var sl_opts = {
    gridPadding: {
        right: 35
    },
    axes: {
        xaxis: {
            renderer: $.jqplot.DateAxisRenderer,
            tickOptions: {
                formatString: '%Y-%m-%d',
                showMark: true,
                showLabel: true,
                showGridline: false
            },
            pad: 0,
            show: false,
            numberTicks: 3
        },
        yaxis: {
            show: false,
            min: 0,
            tickOptions: {
                show: false
            },
            pad: 0
        },
        x2axis: {
            show: false
        },
        y2axis: {
            show: false
        }
    },
    series: [{
        lineWidth: 2,
        showMarker: false,
        color: '#006295',
        shadow: false
    }],
    grid: {
        drawGridLines: false,
        borderWidth: 0,
        shadow: false,
        background: 'transparent'
    }
};

$('.delete').live('click',
function(event) {
    if (confirm("This action can result in data loss. Are you sure?"))
    return true;
});

$('.addcat').live('click',
function(event) {
    $('#categories').append('<div class="category"> <p class="string optional nobreak"><label class="string optional" for="classifier_categories_attributes_1_name">Name</label><input class="string optional" id="classifier_categories_attributes_1_name" maxlength="255" name="classifier[categories_attributes][1][name]" size="50" type="text" /></p><p class="numeric integer optional nobreak" size="4"><label class="integer optional" for="classifier_categories_attributes_1_value">Value</label>  <input class="numeric integer optional" id="classifier_categories_attributes_1_value" name="classifier[categories_attributes][1][value]" step="1" type="number" /></p><p class="text optional"><label class="text optional" for="classifier_categories_attributes_1_description">Description</label>  <textarea class="text optional" cols="70" id="classifier_categories_attributes_1_description" name="classifier[categories_attributes][1][description]" rows="2"></textarea></p> <p class="boolean"><input name="classifier[categories_attributes][1][_destroy]" type="hidden" value="0" /><input id="classifier_categories_attributes_1__destroy" name="classifier[categories_attributes][1][_destroy]" type="checkbox" value="1" /> <label for="classifier_categories_attributes_1__destroy">Remove category</label></p></div>');
});

$('.delcat').live('click',
function(event){mark_for_destroy(this);
});


function mark_for_destroy(element) {
	$(element).prev("input[type=hidden]").val("1");
    $(element).parent().hide();
}



