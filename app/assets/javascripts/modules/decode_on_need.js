/*
  Display/hide applicable "Decide on need" form sections, based on
  the choice of decision
*/
(function(Modules) {
  "use strict";
  Modules.DecideOnNeed = function() {
    var that = this;
    that.start = function(element) {
      var $el = $(element);
      var $allFieldsets = $el.find('fieldset[data-status-description]');

      $el.find('input.new-status-description').change(function(){
        $el.find('.decide-on-need-submit-button').attr('disabled', false);

        var selectedStatusDescription = $(this).val();
        var $relevantFieldset = $el.find('fieldset[data-status-description="' + selectedStatusDescription + '"]');

        $relevantFieldset.show();
        $allFieldsets.not($relevantFieldset).hide();
      });

      $allFieldsets.hide();
    }
  };
})(window.GOVUKAdmin.Modules);
