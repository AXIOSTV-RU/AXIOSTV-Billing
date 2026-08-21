<script language='JavaScript'>



  async function readTag() {

    if ("NDEFReader" in window) {

      const ndef = new NDEFReader();
      try {
        //jQuery('#read_tag_button').show()
        await ndef.scan();
        //jQuery('#read_tag_button').hide()
        ndef.onreading = event => {
          const decoder = new TextDecoder();


          var 
            key = event.serialNumber,
            aKey = key.split(':'),
            result_key = ''

          aKey.reverse()

          result_key = aKey.join('')
          // 000000 6e8a176b 8 и 6 = 14
          for (var i = 14 - result_key.length; i > 0; i--) {
            result_key = '0'+result_key
          }
          jQuery('#add_key__key').val(result_key)

        }


      } catch(error) {
        console.log(error);
      }
    } else {
      console.log("Web NFC is not supported.");
    }
  }

  window.addEventListener("load", function() {

    if ("NDEFReader" in window) {
      readTag() 
    } else {
      console.log("Web NFC is not supported.");
    }

    jQuery('#read_tag_button').click(function(e){
      e.preventDefault()
      readTag()
    })



    jQuery('#add_key__submit').click(function(e){
      e.preventDefault()

      var 
        add_key__comment = jQuery('#add_key__comment').val(),
        add_key__key = jQuery('#add_key__key').val()


      let result = add_key__key.match(/[0-9A-Fa-f]{1,30}/g);
      if (result) {
          console.log("Valid");
      } else {
          alert('Неправильный формат ключа')
          return false
      }



      jQuery('#add_key_form').hide()

      location.href = '/admin/index.cgi?UID='+%UID%+'&comment='+add_key__comment+'&add_key__key='+add_key__key+'&add_user_keys_do=true&index=%index%'
/*      jQuery.ajax({
        url: '/admin/index.cgi?UID='+%UID%+'&comment='+add_key__comment+'&add_key__key='+add_key__key+'&add_user_keys_do=true&index=%index%',
        method: 'get',
        dataType: 'html',
        //data: {text: 'Текст'},
        success: function(data){
          location.reload() 
        }
      });*/
    })

    var add_key_link = jQuery('#CAMERAS_KEYS_ID_').prev().prev().find('a')
    
    add_key_link.click(function(e){
      e.preventDefault()
      readTag()
      jQuery('#add_key_form').toggle()
    })


    /* Массовое удаление */
    jQuery('#add_key_form').parent().next().click(function(e){
      e.preventDefault()

      var selectedItems = ''
      jQuery('#CAMERAS_KEYS_ID_ tr').each(function(index,item){
        var item = jQuery(item)
        item.find('input').prop('checked')
        if (item.find('input').prop('checked')) {
          selectedItems += item.find('td').eq(0).text() + ','
        }
      })
      selectedItems = selectedItems.substring(0, selectedItems.length - 1);
      //console.log(selectedItems)
      location.href = '/admin/index.cgi?UID=%UID%&index=%index%&DELETE_KEYS_IDS='+selectedItems
    })

    
  })






</script>

<form action='$SELF_URL' method=post name='cams_user_info' class='form-horizontal'>
 
  <div class='card card-primary card-outline card-form' id="add_key_form" style="display:none" >
    <div class='card-header with-border'>
      <h3 class='card-title'>Добавить ключ</h3>
    </div>
    <div class='card-body'>
     
      <div id="demoMSG"></div>

      
      <div class='form-group row'>
        <label class='control-label col-md-3' for='EMAIL'>Ключ:</label>
        <div class='col-md-9'>
          <input id='add_key__key' name='add_key__key' value='' placeholder='' class='form-control' type='text'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='EMAIL'>Комментарий:</label>
        <div class='col-md-9'>
          <input id='add_key__comment' name='add_key__comment' value='' placeholder='' class='form-control' type='text'>
        </div>
      </div>
      <!--<a href="#" class="btn btn-default" id="read_tag_button"  onclick="">Запросить разрешение</a>      -->

    
            
    </div>
    <div class='card-footer'>      
      <a class='btn btn-primary' id='add_key__submit' >Добавить</a>
    </div>
  </div>

</form>


