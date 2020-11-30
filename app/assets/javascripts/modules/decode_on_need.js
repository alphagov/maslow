/*
  Display/hide applicable "Decide on need" form sections, based on
  the choice of decision
*/
(function (Modules) {
  'use strict'
  Modules.DecideOnNeed = function () {
    var that = this
    that.start = function (element) {
      element.find('input.new-status-description').change(displayRelevantFormFieldset)
      displayRelevantFormFieldset() // this arranges the form up correctly when it's first loaded

      function displayRelevantFormFieldset () {
        var selectedStatusDescription = element.find('input.new-status-description:checked').val()
        var $relevantFieldset = element.find('fieldset[data-status-description="' + selectedStatusDescription + '"]')

        $relevantFieldset.show()

        var $allFieldsets = element.find('fieldset[data-status-description]')
        $allFieldsets.not($relevantFieldset).hide()
      };
    }
  }
})(window.GOVUKAdmin.Modules)
