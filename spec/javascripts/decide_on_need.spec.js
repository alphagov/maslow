describe('A "Decide on need" module', function () {
  'use strict'

  var module
  var $element

  beforeEach(function () {
    $element = $('<form></form>')
      .append('<input checked="true" id="option-a" name="option" class="new-status-description" type="radio" value="option A">')
      .append('<input id="option-b" name="option" class="new-status-description" type="radio" value="option B">')
      .append('<fieldset id="fields-for-a" data-status-description="option A">')
      .append('<fieldset id="fields-for-b" data-status-description="option B">')
    $('body').append($element)
    module = new GOVUKAdmin.Modules.DecideOnNeed()
  })

  afterEach(function () {
    $element.remove()
  })

  it('shows the relevant fieldset for the preselected value', function () {
    module.start($element)

    expect($('#fields-for-a').is(':visible')).toBe(true)
    expect($('#fields-for-b').is(':visible')).toBe(false)
  })

  it('shows the relevant fieldset when an option is selected', function () {
    module.start($element)

    $('#option-b').click()
    expect($('#fields-for-a').is(':visible')).toBe(false)
    expect($('#fields-for-b').is(':visible')).toBe(true)
  })
})
