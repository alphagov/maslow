describe('A scroll to element module', function () {
  'use strict'

  var module
  var element

  beforeEach(function () {
    element = $('<div></div>')
    $('body').append(element)
    module = new GOVUKAdmin.Modules.ScrollToElement()
  })

  afterEach(function () {
    element.remove()
  })

  it('scrolls to its element when it starts', function () {
    spyOn(window, 'scrollTo')
    module.start(element)
    expect(window.scrollTo).toHaveBeenCalledWith(0, element.offset().top)
  })
})
