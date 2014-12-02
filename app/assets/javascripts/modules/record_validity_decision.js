/*
  Display/hide applicable "record validity decision" form sections, based on
  the choice of decision
*/
(function(Modules) {
  "use strict";
  Modules.RecordValidityDecision = function() {
    var that = this;
    that.start = function(element) {
      var $el = $(element);
      var $allFieldsets = $el.find('fieldset[data-status-description]');

      $el.find('input.new-status-description').change(function(){
        $el.find('.record-validity-decision-submit-button').attr('disabled', false);

        var selectedStatusDescription = $(this).val();
        var $relevantFieldset = $el.find('fieldset[data-status-description="' + selectedStatusDescription + '"]');

        $relevantFieldset.show();
        $allFieldsets.not($relevantFieldset).hide();
      });

      $allFieldsets.hide();
    }
  };
})(window.GOVUKAdmin.Modules);
