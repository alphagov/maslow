$(function(){
  $('#record-validity-decision-button').
    attr('href', '#record-validity-decision-modal').
    attr('data-toggle', 'modal').
    attr('role', 'button');

  $('input.new-status-description').change(function(){
    $('.record-validity-decision-submit-button').attr('disabled', false);

    var value = $(this).val();
    $('.conditional').hide();
    $('fieldset[data-status-description="' + value + '"]').show();
  });

  $('.conditional').hide();
});
