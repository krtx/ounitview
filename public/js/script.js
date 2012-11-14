
$(document).ready(function () {
    var levels = ['success', 'skip', 'todo', 'failure', 'error'];

    var toggle_passed = function () {
        $.each(levels, function (idx) {
            if ($.inArray(levels[idx], ['success']) >= 0)
                $('.test.' + levels[idx]).toggle();
        });
    };

    $('#toggle').click(toggle_passed);

    $('span.node-path').click(function (ev) {
        $(ev.target).parent().next('.path-list').toggle();
    });
});

