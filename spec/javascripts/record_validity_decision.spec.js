describe('A "record validity decision" module', function() {
  "use strict";

  var root = window,
      module,
      $element;

  beforeEach(function() {
    $element = $('<form></form>').
                append('<input id="option-a" class="new-status-description" type="radio" value="option A">').
                append('<input id="option-b" class="new-status-description" type="radio" value="option B">').
                append('<fieldset id="fields-for-a" data-status-description="option A">').
                append('<fieldset id="fields-for-b" data-status-description="option B">');
    $('body').append($element);
    module = new GOVUKAdmin.Modules.RecordValidityDecision();
  });

  afterEach(function() {
    $element.remove();
  });

  it('hides all fieldsets by default', function() {
    module.start($element);

    expect($('#fields-for-a').is(':visible')).toBe(false);
    expect($('#fields-for-b').is(':visible')).toBe(false);
  });

  it('shows the relevant fieldset when an option is selected', function() {
    module.start($element);

    $('#option-a').click();
    expect($('#fields-for-a').is(':visible')).toBe(true);
    expect($('#fields-for-b').is(':visible')).toBe(false);

    $('#option-b').click();
    expect($('#fields-for-a').is(':visible')).toBe(false);
    expect($('#fields-for-b').is(':visible')).toBe(true);
  });
});
