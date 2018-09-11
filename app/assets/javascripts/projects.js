// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$( document ).on('ready turbolinks:load', function() {

  var windowObjectReference;
  var strWindowFeatures = "menubar=no,location=no,resizable=yes,scrollbars=no,status=no,width=500,height=400";

  function openRequestedPopup() {
    windowObjectReference = window.open(_scorecard_path, _scorecard_title, strWindowFeatures);
  }

  function refreshParent() {
    window.opener.location.reload();
  }

  $('#open-scorecard').click(function (event) {
    event.preventDefault();
    openRequestedPopup();
  });

  $('#close-scorecard').click(function (event) {
    event.preventDefault();
    window.close();
  });

});