/*
  Display/hide applicable "Decide on need" form sections, based on
  the choice of decision
*/
(function(Modules) {
  "use strict";
  Modules.DecideOnNeed = function() {
    var that = this;
    that.start = function(element) {
      var $allFieldsets = element.find('fieldset[data-status-description]');

      element.find('input.new-status-description').
        change(enableSubmitButton).
        change(displayRelevantFormField);

      $allFieldsets.hide();

      function displayRelevantFormField() {
        var selectedStatusDescription = $(this).val();
        var $relevantFieldset = element.find('fieldset[data-status-description="' + selectedStatusDescription + '"]');

        $relevantFieldset.show();
        $allFieldsets.not($relevantFieldset).hide();
      };

      function enableSubmitButton() {
        element.find('.decide-on-need-submit-button').attr('disabled', false);
      };
    };
  };
})(window.GOVUKAdmin.Modules);
