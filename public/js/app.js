$( document ).ready(function() {
  align_marc_views();
});
$( window ).resize(function() {
  align_marc_views();
});
function align_marc_views() {
  // align the heights of the marc view and xml divs
  if ($('#marc-view').length && $('#marc-xml').length) {
    $('#marc-xml').height($('#marc-view').height());
    $('#marc-xml').width($('#marc-view').width());
  }
 }