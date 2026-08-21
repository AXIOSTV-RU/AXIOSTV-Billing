<script language='JavaScript'>
  function autoReload() {
    document.cams_user_info.add_form.value = '1';
    document.cams_user_info.TP_ID.value = '';
    document.cams_user_info.new.value = '$FORM{new}';
    document.cams_user_info.step.value = '$FORM{step}';
    document.cams_user_info.submit();
  }
  window.addEventListener("load", function() {
    
    //jQuery('body').hide();
    jQuery('#add_user_rights_input').click(function(e){
      e.preventDefault()

      var selectedItems = ''
      jQuery('#add_user_rights tr').each(function(index,item){
        var item = jQuery(item)
        item.find('input').prop('checked')
        if (item.find('input').prop('checked')) {
          selectedItems += item.find('td').eq(1).text() + ', '
        }
      })
      selectedItems = selectedItems.substring(0, selectedItems.length - 2);
      
      location.href = '/admin/index.cgi?UID=%UID%&index=%index%&add_user_rights_do='+selectedItems
    })



    var add_rights_link = jQuery('#p_CAMERAS_RIGHTS_ID .card-tools:eq(0) a').eq(0)
    
    add_rights_link.click(function(e){
      e.preventDefault()
    
      jQuery('#add_user_rights_form').toggle()
    })
    
  })
</script>

<style>
.card.card-form {
  max-width: 100%;
}
</style>

<form action='$SELF_URL' method=post name='cams_user_info'  class='form-horizontal'>
  <input type=hidden name=index value=$index>
  <input type=hidden name=ID value='$FORM{chg}'>
  <input type=hidden name=UID value='$FORM{UID}'>
  <input type=hidden name=TP_IDS value='%TP_IDS%'>
  <input type=hidden name='step' value='$FORM{step}'>
  <input type=hidden name='new' value=''>
  <input type=hidden name='add_form' value=''>

  %NEXT_FEES_WARNING%
  <div class='card card-primary card-outline card-form' id="add_user_rights_form" style="_display:none" >
    <div class='card-header with-border'>
      <h3 class='card-title'>Добавление камеры подписки</h3>
    </div>
    <div class='card-body'>
      
      %html%

      
      
      
    <div class='card-footer'>
      %BACK_BUTTON%
      <input type='submit' class='btn btn-primary' id='add_user_rights_input' name='%ACTION%' value='Добавить'>
    </div>

    </div>
  </div>

</form>


